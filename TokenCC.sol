// SPDX-License-Identifier: GPL-3.0-or-later

//Daniel Zhao (fmd3ed)

// This file is part of the http://github.com/aaronbloomfield/ccc repository,
// and is released under the GPL 3.0 license.

pragma solidity ^0.8.24;

import "./ITokenCC.sol";
import "./ERC20.sol";

contract TokenCC is ITokenCC, ERC20 {
    constructor(){
        
    }
}