from web3 import Web3
from web3.middleware import geth_poa_middleware
import json
import arbitrage_config
from hexbytes import HexBytes



if arbitrage_config.config['connection_is_ipc']:
    w3 = Web3(Web3.IPCProvider(arbitrage_config.config['connection_uri']))
else:
    w3 = Web3(Web3.WebsocketProvider(arbitrage_config.config['connection_uri']))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)
# print(w3.is_connected())
# Set up account using the private key
account = w3.eth.account.from_key(arbitrage_config.config['account_private_key'])

# Contract setup
dex_abi = json.loads(arbitrage_config.idex_abi)  # Assume ABI is correctly formatted JSON string
token_abi = json.loads(arbitrage_config.itokencc_abi)  # Assume ABI is correctly formatted JSON string

# Instantiate contract objects
dex_contracts = [
    w3.eth.contract(address= Web3.to_checksum_address(addr), abi=dex_abi)
    for addr in arbitrage_config.config['dex_addrs']
]

account = Web3.to_checksum_address(arbitrage_config.config["account_address"])


token_contract = w3.eth.contract(address= Web3.to_checksum_address(arbitrage_config.config['tokencc_addr']), abi=token_abi)
q_e = w3.eth.get_balance(Web3.to_checksum_address(arbitrage_config.config["account_address"])) * 1e-18  # quantity ETH
q_t = token_contract.functions.balanceOf(Web3.to_checksum_address(arbitrage_config.config["account_address"])).call() / 10 ** 10  # quantity TC

# print('account',arbitrage_config.config["account_address"])
# print('balances',q_e,q_t)
p_e = arbitrage_config.config["price_eth"]  # current price ETH in USD
p_t = arbitrage_config.config["price_tc"]  # current price TC in USD

h_before = q_e*p_e + q_t*p_t
# print('starting funds', h_before)


# Function to calculate optimal trade amounts
def calculate_optimal_trade_amounts(f, kd, pe, pt, yd, xd):
    # Simplified formula to calculate delta_t and delta_e
    # print(yd, xd)
    delta_t = -yd + ((f * kd * (pe / pt))**0.5)
    delta_e = -xd + ((f * kd * (pt / pe))**0.5)
    return delta_t, delta_e

def evaluate_profitability(dex_contracts):
    h_before = q_e * arbitrage_config.config["price_eth"] + q_t * arbitrage_config.config["price_tc"]
    best = 0
    txn = None
    bdelta_t = 0
    bdelta_e=0
    bfee = 0
    best_hAfter = 0

    for dex_contract in dex_contracts:
        # print('contract:', dex_contract)
        # eth_reserve = dex_contract.functions.ethReserve().call()

        # tc_reserve = dex_contract.functions.tcReserve().call()
        feeN = dex_contract.functions.feeNumerator().call()
        feeD = dex_contract.functions.feeDenominator().call()
        f = 1 - feeN / feeD

        # Example: Fetch other necessary data if required
        x_d = dex_contract.functions.x().call() 
        y_d = dex_contract.functions.y().call() 
        k_d = dex_contract.functions.k().call() 

        # print(f"Contract: {dex_contract.address}, Fee: {f}, Liquidity ETH: {x_d}, Liquidity Tokens: {y_d}")

        delta_t, delta_e = calculate_optimal_trade_amounts(f, k_d / 10**28, arbitrage_config.config["price_eth"], arbitrage_config.config["price_tc"], y_d/10**10, x_d/10**18)


        # print('qeeee: ', q_e)
        delta_e = max(0, min(q_e, min(int(arbitrage_config.config['max_eth_to_trade']), delta_e)))
        delta_t = max(0, min(q_t, min(int(arbitrage_config.config['max_tc_to_trade']), delta_t)))
        # print(f"Delta ETH: {delta_e}, Delta Tokens: {delta_t}")

        profitEth = 0
        profitToken=0
        if delta_e>0:

            transactionE = {
                'from': account,
                'nonce': w3.eth.get_transaction_count(account),
                'to': dex_contract.address,
                'value': w3.to_wei(delta_e, 'ether'),
                'gas': 210000,
                'gasPrice': w3.to_wei(arbitrage_config.config["gas_price"], 'gwei'),
                'chainId': arbitrage_config.config["chainId"],
            }

            # Estimating the gas cost for the transaction
            estimated_gas = w3.eth.estimate_gas(transactionE)
            gas_price_wei = w3.to_wei(arbitrage_config.config["gas_price"], 'gwei')  # Gas price should be in Wei
            total_gas_cost_wei = estimated_gas * gas_price_wei

            # Now convert the total gas cost to Ether for comparisons or cost calculations
            total_gas_cost_eth = w3.from_wei(total_gas_cost_wei, 'ether')
            # print('gas cost eth',total_gas_cost_eth)
            # If you need to calculate the cost in USD:
            total_gas_cost_usd1 = float(total_gas_cost_eth) * arbitrage_config.config['price_eth']


            tokenLeft = (k_d*10**-28)/(delta_e+x_d*10**-18)

            profitEth = (y_d*10**-10-tokenLeft)*f*arbitrage_config.config['price_tc'] - float(delta_e)*int(arbitrage_config.config['price_eth']) - float(total_gas_cost_usd1)
            # print('profitseth', profitEth)

    
        # print(delta_t)
        if delta_t>0:
            transactionT = token_contract.functions.transfer(dex_contract.address, int(delta_t*10**10)).build_transaction({
                'gas': 210000,
                'gasPrice': w3.to_wei(arbitrage_config.config["gas_price"], 'gwei'),
                'from': account,
                'nonce': w3.eth.get_transaction_count(account),
                'chainId': arbitrage_config.config["chainId"],
            })
            estimated_gas = w3.eth.estimate_gas(transactionT)
            gas_price_wei = w3.to_wei(arbitrage_config.config["gas_price"], 'gwei')  # Gas price should be in Wei
            total_gas_cost_wei = estimated_gas * gas_price_wei

            # Now convert the total gas cost to Ether for comparisons or cost calculations
            total_gas_cost_eth = w3.from_wei(total_gas_cost_wei, 'ether')

            # If you need to calculate the cost in USD:
            total_gas_cost_usd2 = float(total_gas_cost_eth) * arbitrage_config.config['price_eth']
            ethleft = (k_d*10**-28)/(delta_t+y_d*10**-10)

            # print('prices', ethleft,float(delta_t), total_gas_cost_usd2)
            profitToken = (x_d*10**-18-ethleft)*f*arbitrage_config.config['price_eth'] - float(delta_t)*int(arbitrage_config.config['price_tc']) - float(total_gas_cost_usd2)
            # print('profits and lefts',ethleft,profitToken)

        # print('profitst then e', profitToken, profitEth)
        if profitToken>best:
            best = profitToken
            txn = transactionT
            best_hAfter = h_before+profitToken
            bdelta_e = (x_d*10**-18-ethleft)*f
            bdelta_t = -delta_t
            bfee = total_gas_cost_usd2
        if profitEth>best:
            best = profitEth
            txn = transactionE
            best_hAfter = h_before+profitEth
            bdelta_e = -delta_e
            bdelta_t = (y_d*10**-10-tokenLeft)*f
            bfee = total_gas_cost_usd1

    if txn:
        # print(txn)
        signed_txn = w3.eth.account.sign_transaction(txn, private_key= arbitrage_config.config['account_private_key'])
        ret = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
        # print(bdelta_e, bdelta_t)
    arbitrage_config.output(bdelta_e, bdelta_t, bfee,best_hAfter)

    # arbitrage_config.output

# Main function to run arbitrage strategy
def main():
    # perform_best_arbitrage_trade()
    evaluate_profitability(dex_contracts)

if __name__ == "__main__":
    main()
