// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "./IDEX.sol";
import "./IERC165.sol";
import "./IEtherPriceOracle.sol";
import "./IERC20Receiver.sol";
import "./ERC20.sol";

contract DEX is IDEX{
    // State variables
    address public owner;
    bool private transfer;
    uint public x; // Ether liquidity
    uint public y; // Token liquidity
    uint public k; // Product of x and y
    uint public feeNumerator;
    uint public feeDenominator;
    uint public feesEther;
    uint public feesToken;
    ERC20 public token;
    IEtherPriceOracle public etherpricer;
    mapping(address => uint) public etherLiquidityForAddress;
    mapping(address => uint) public tokenLiquidityForAddress;

    constructor(){
        owner = msg.sender;
        transfer = false;
    }

    function decimals() external view override returns(uint){
        return token.decimals();
    }

    function symbol() external view override returns (string memory) {
        return token.symbol();
    }

    function getEtherPrice() external view override returns(uint){
        return etherpricer.price();
    }


    //to revisit
    function getTokenPrice() external view override returns(uint){
        uint etherPrice = etherpricer.price();
        return (etherPrice * y) / x;
    }

    function getPoolLiquidityInUSDCents() external view override returns(uint){
        uint etherPrice = etherpricer.price();
        return 2* etherPrice*x;
    }

    function createPool(uint _tokenAmount, uint _feeNumerator, uint _feeDenominator, 
                        address _erc20token, address _etherPricer) external payable override{
        transfer = true;
        require(x == 0 && y == 0, "Pool already created");
        require(msg.sender==owner,"you cant create the pool");   

        x+=msg.value;
        // uint tokenDecimals = token.decimals();
        y += _tokenAmount; // Adjust for token decimals
        // y+=_tokenAmount;
        k = x*y; 

        token = ERC20(_erc20token);
        etherpricer = IEtherPriceOracle(_etherPricer);
        feeNumerator = _feeNumerator;
        feeDenominator = _feeDenominator;

        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        emit liquidityChangeEvent();
        transfer = false;
    }

    function addLiquidity() external payable override {
        transfer = true;
        require(x > 0 && y > 0, "Pool not created yet");
        require(msg.value > 0, "Must add positive ETH amount");
        // uint tokenDecimals = token.decimals();
        uint tokenAmount = ((msg.value * y) / x);
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        x += msg.value;
        y += tokenAmount;
        k = x * y;

        etherLiquidityForAddress[msg.sender] += msg.value;
        tokenLiquidityForAddress[msg.sender] += tokenAmount;

        emit liquidityChangeEvent();
        transfer = false;
    }

    function removeLiquidity(uint amountWei) external override {
        transfer = true;
        require(amountWei > 0, "Must remove positive amount");
        require(etherLiquidityForAddress[msg.sender] >= amountWei, "Insufficient liquidity");

        // uint tokenDecimals = token.decimals();
        uint tokenAmount = ((amountWei * y) / x);
        require(tokenLiquidityForAddress[msg.sender] >= tokenAmount, "Insufficient token liquidity");

        x -= amountWei;
        y -= tokenAmount;
        k = x * y;

        etherLiquidityForAddress[msg.sender] -= amountWei;
        tokenLiquidityForAddress[msg.sender] -= tokenAmount;

        payable(msg.sender).transfer(amountWei);
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit liquidityChangeEvent();
        transfer = false;

    }

    receive() external payable override { 
        require(x > 0 && y > 0, "Pool not initialized");
        uint256 inputAmount = msg.value;
        // uint tokenDecimals = token.decimals();
        uint256 tokenAmount = ((inputAmount * y) / (x + inputAmount));
        uint256 fee = (tokenAmount * feeNumerator) / feeDenominator;
        uint256 amountToPayOut = tokenAmount - fee;

        x += inputAmount;
        y -= amountToPayOut;// Update liquidity using the full token amount
        feesToken += fee; // Accumulate the fee in tokens

        require(token.transfer(msg.sender, amountToPayOut), "Token transfer failed");
        emit liquidityChangeEvent();
    }

    function onERC20Received(address from, uint amount, address erc20) external override returns (bool){
        if (!transfer) {
            require(erc20 == address(token), "Unsupported token");
            require(x > 0 && y > 0, "Pool not initialized");

            // uint tokenDecimals = token.decimals();
            uint256 tokenAmount = amount;
            uint256 etherAmount = (tokenAmount * x) / (y + tokenAmount);
            uint256 fee = (etherAmount * feeNumerator) / feeDenominator;
            uint256 amountToPayOut = etherAmount - fee;

            y += tokenAmount;
            x -= amountToPayOut; // Update liquidity using the full ether amount
            feesEther += fee; // Accumulate the fee in ether

            (bool success, ) = payable(from).call{value: amountToPayOut}("");
            require(success, "Failed to transfer ETH");
            emit liquidityChangeEvent();

            return true;
        }
        return true;
    }

    function setEtherPricer(address p) external override {
        etherpricer = IEtherPriceOracle(p);
    }

    function etherPricer() external view override returns (address){
        return address(etherpricer);
    }

    function ERC20Address() external view override returns(address){
        return address(token);
    }

    function getDEXinfo() external view override returns (address, string memory, string memory, 
                            address, uint, uint, uint, uint, uint, uint, uint, uint){
        return (
            address(this),              // DEX contract address
            token.symbol(),             // Token cryptocurrency abbreviation
            token.name(),               // Token cryptocurrency name
            address(token),             // ERC-20 token cryptocurrency address
            k,                          // Constant product k
            x,                          // Ether liquidity
            y,                          // Token liquidity
            feeNumerator,               // Fee numerator
            feeDenominator,             // Fee denominator
            token.decimals(),           // Token decimals
            feesEther,                  // Fees collected in ether
            feesToken                   // Fees collected in the token
    );
    }

    function reset() external override {
        revert();
    }



    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC20Receiver).interfaceId
            || interfaceId == type(IDEX).interfaceId;
    }
}