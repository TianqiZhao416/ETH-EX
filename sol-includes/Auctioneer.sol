// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "./IAuctioneer.sol";
import "./NFTManager.sol";

contract Auctioneer is IAuctioneer {
    NFTManager private Nftmanager;
    uint256 public NumAuctions;
    mapping( uint => Auction ) private Auctions;
    mapping (uint => bool) private auctionExists;
    address private Deployer;
    uint private totalFee;
    uint private balance;
    constructor(){
        Nftmanager = new NFTManager("Minter", "MT");
        Deployer = msg.sender;
        totalFee = 0;
        balance = 0;
    }

    function nftmanager() public view override returns(address){
        return address(Nftmanager);
    }

    function numAuctions() public view override  returns(uint){
        return NumAuctions;
    }

    function totalFees() public view override  returns(uint){
        return totalFee;
    }

    function uncollectedFees() public view  returns(uint){
        return balance;
    }

    function deployer() public view returns(address){
        return Deployer;
    }

    function collectFees() external override{
        // require(msg.sender==Deployer, "you cant")
        require(balance>0,"You dont have anything to collect");
        (bool success, ) = payable(Deployer).call{value: balance}("");
        balance = 0;
        require(success, "Failed to transfer Ether to the initiator");
    }


    // Start an auction.  The first three parameters are the number of
    // minutes, hours, and days for the auction to last -- they can't all be
    // zero.  The data parameter is a textual description of the auction, NOT
    // the file name; it can't be the empty string.  The reserve is the
    // minimum price that will win the auction; this amount is in wei
    // (which is 10^-18 eth), and can be zero.  The nftid is which NFT is
    // being auctioned.  This function has four things it must do: sanity
    // checks (verify valid parameters, ensure no auction with that NFT ID is
    // running), transfer the NFT over to this contract (revert if it can't),
    // create the Auction struct (which effectively starts the auction), and
    // emit the appropriate event. This returns the auction ID of the newly
    // configured auction.  These auction IDs have to start from 0 for the
    // auctions.php web page to work properly.  Note that only the owner of a
    // NFT can start an auction for it, and this should be checked via
    // require().  Make sure the account used is msg.sender, not deployer!
    // Otherwise it will work for you but not for any of our grading tests.
    function startAuction(uint m, uint h, uint d, string memory data, 
                        uint reserve, uint nftid) external override returns (uint) {
        require(!auctionExists[nftid]|| !Auctions[nftid].active, "Auction already exists/active");
        require(m != 0 || h != 0 || d != 0, "Auction duration cannot be zero");
        require(bytes(data).length > 0, "Auction data cannot be empty");
        require(Nftmanager.ownerOf(nftid) == msg.sender, "Only the NFT owner can start an auction");

        // Transfer the NFT from the sender to this contract
        Nftmanager.transferFrom(msg.sender, address(this), nftid);

        // Calculate the auction end time
        uint endTime = block.timestamp + (m * 1 minutes) + (h * 1 hours) + (d * 1 days);

        // Create and store the new auction
        Auctions[nftid] = Auction({
            id: nftid,
            num_bids: 0,
            data: data,
            highestBid: reserve,
            winner: address(0), // No winner yet
            initiator: msg.sender,
            nftid: nftid,
            endTime: endTime,
            active: true
        });

        // Update the auction existence mapping
        auctionExists[nftid] = true;

        // Increment the total number of auctions
        NumAuctions++;

        // Emit the auction start event
        emit auctionStartEvent(nftid);

        // Return the auction ID (which is the same as the NFT ID in this case)
        return nftid;
    }
    // The time left (in seconds) for the given auction, the ID of which is
    // passed in as a parameter.  This is a convenience function, since it's
    // much easier to call this rather than get the end time as a UNIX
    // timestamp.
    function auctionTimeLeft(uint id) public view override returns (uint) {
        require(auctionExists[id], "Auction does not exist");

        if (block.timestamp >= Auctions[id].endTime) {
            return 0; // Auction has ended
        } else {
            return Auctions[id].endTime - block.timestamp; // Time left until auction ends
        }
    }
    // This closes out the auction, the ID of which is passed in as a
    // parameter.  It first does the basic sanity checks (you have to figure
    // out what).  If bids were placed, then it will transfer the ether to
    // the initiator.  It will handle the transfer of the  NFT (to the
    // initiator if no bids were placed or to the winner if bids were placed)
    // In the latter case, it keeps 1% fees and emits the appropriate event.
    // The auction is marked as inactive. Note that anybody can call this
    // function, although it will only close auctions whose time has
    // expired.
    /* 
        struct Auction {
            uint id;            // the auction id
            uint num_bids;      // how many bids have been placed
            string data;        // a text description of the auction or NFT data
            uint highestBid;    // the current highest bid, in wei
            address winner;     // the current highest bidder
            address initiator;  // who started the auction
            uint nftid;         // the NFT token ID
            uint endTime;       // when the auction ends
            bool active;        // if the auction is active
        }
    */
    function closeAuction(uint id) external override {
        require(Auctions[id].active, "Auction is already inactive");
        require(auctionTimeLeft(id) == 0, "Auction has not ended");

        if (Auctions[id].num_bids == 0) {
            // No bids were placed, transfer the NFT back to the initiator
            Nftmanager.transferFrom(address(this), Auctions[id].initiator, id);
        } else {
            // Bids were placed, transfer the NFT to the winner
            Nftmanager.transferFrom(address(this), Auctions[id].winner, id);

            // Calculate the fee (1%) and the amount to transfer to the initiator
            uint fee = Auctions[id].highestBid / 100;
            uint amountToTransfer = Auctions[id].highestBid - fee;

            // Transfer the Ether to the initiator
            (bool success, ) = payable(Auctions[id].initiator).call{value: amountToTransfer}("");
            require(success, "Failed to transfer Ether to the initiator");

            // Update the total fee and balance
            totalFee += fee;
            balance += fee;

            // Emit the auction close event
            emit auctionCloseEvent(id);
        }

        // Mark the auction as inactive
        Auctions[id].active = false;
    }

    // When one wants to submit a bid on a NFT; the ID of the auction is
    // passed in as a parameter, and some amount of ETH is transferred with
    // this function call (that amount is in msg.value, which is in wei).  So
    // many sanity checks here!  See the homework description some of various
    // cases where this function should revert; you get to figure out the
    // rest.  On a successful higher bid, it should update the auction
    // struct.  Be sure to refund the previous higher bidder, since they have
    // now been outbid.
    function placeBid(uint id) payable external override {
        require(auctionExists[id], "Auction does not exist");
        require(Auctions[id].active, "Auction is not active");
        require(block.timestamp < Auctions[id].endTime, "Auction has ended");
        require(msg.value > Auctions[id].highestBid, "Bid must be higher than the current highest bid");

        address previousWinner = Auctions[id].winner;
        uint previousHighestBid = Auctions[id].highestBid;

        Auctions[id].highestBid = msg.value;
        Auctions[id].winner = msg.sender;
        Auctions[id].num_bids++;

        // Refund the previous highest bidder if there was one
        if (previousWinner != address(0)) {
            (bool success, ) = payable(previousWinner).call{value: previousHighestBid}("");
            require(success, "Failed to refund previous highest bidder");
        }

        emit higherBidEvent(id);
    }

    function auctions(uint id) public view override returns(uint, uint, string memory, uint, address, address, uint, uint, bool) {
        require(auctionExists[id], "auction doesn't exist");
        Auction storage auction = Auctions[id];
        return (
            auction.id,
            auction.num_bids,
            auction.data,
            auction.highestBid,
            auction.winner,
            auction.initiator,
            auction.nftid,
            auction.endTime,
            auction.active
        );
    }
    // function auctions(uint id) public view override  returns(uint, uint, string memory, uint, address, address, uint, uint, bool){
    //     require(auctionExists[id], "auction doesn't exist");
    //     return Auction[id];
    // }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAuctioneer).interfaceId;
    }
}