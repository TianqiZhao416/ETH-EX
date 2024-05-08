// SPDX-License-Identifier: GPL-3.0-or-later
//Daniel Zhao fmd3ed
// This file is part of the http://github.com/aaronbloomfield/ccc repository,
// and is released under the GPL 3.0 license.

pragma solidity ^0.8.24;

import "./INFTManager.sol";
import "./ERC721.sol";

contract NFTManager is INFTManager, ERC721 {
    uint256 public override count = 0;
    mapping(uint256 => string) private _tokenURIs;
    mapping(string => bool) private _uriExists;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
    // function mintWithURI(address _to, string memory _uri) external returns (uint);
    function mintWithURI(address _to, string memory _uri) external override returns(uint){
        require(!_uriExists[_uri], "URI already exists");

        uint256 tokenId = ++count;
        _mint(_to, tokenId);
        // _setTokenURI(tokenId, _uri);
        _uriExists[string.concat(_baseURI(), _uri)] = true;
        _tokenURIs[tokenId]=string.concat(_baseURI(), _uri);

        return tokenId;
    }
    // // This also creates a NFT, but assumes `msg.sender` is who the NFT is
    // // for; it can just call the previous function.
    // function mintWithURI(string memory _uri) external returns (uint);
    function mintWithURI(string memory _uri) external override returns(uint){
        require(!_uriExists[_uri], "URI already exists");

        uint256 tokenId = ++count;
        _mint(msg.sender, tokenId);
        // _setTokenURI(tokenId, _uri);
        _uriExists[string.concat(_baseURI(), _uri)] = true;
        _tokenURIs[tokenId]=string.concat(_baseURI(), _uri);

        return tokenId;
    }


    // function count() external returns (uint){
    //     return Count;
    // }
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, IERC721Metadata) returns (string memory) {
        require(_uriExists[_tokenURIs[tokenId]], "The nft you seek doesn't exist");

        // string memory baseURI = _baseURI();
        // return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://andromeda.cs.virginia.edu/ccc/ipfs/files/";
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(INFTManager).interfaceId;
    }
}