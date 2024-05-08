// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;
import "./IEtherPriceOracle.sol";

contract EtherPriceOracleConstant is IEtherPriceOracle {
    string public constant name = "A constant EtherPrice oracle that always returns $100.00";
    string public constant symbol = "$";
    uint public constant decimals = 2;
    uint public constant price = 10000; // in cents

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IEtherPriceOracle).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}