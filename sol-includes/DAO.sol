// SPDX-License-Identifier: GPL-3.0-or-later

// This file is part of the http://github.com/aaronbloomfield/ccc repository,
// and is released under the GPL 3.0 license.

pragma solidity ^0.8.24;

import "./IDAO.sol";
import "./NFTManager.sol";

contract DAO is IDAO {
    //------------------------------------------------------------
    // A struct to hold all of our proposal data

    // struct Proposal {
    //     address recipient;      // The address where the `amount` will go to if the proposal is accepted
    //     uint amount;            // The amount to transfer to `recipient` if the proposal is accepted.
    //     string description;     // The amount to transfer to `recipient` if the proposal is accepted.
    //     uint votingDeadline;    // A UNIX timestamp, denoting the end of the voting period
    //     bool open;              // True if the proposal's votes have yet to be counted, otherwise False
    //     bool proposalPassed;    // True if the votes have been counted, and the majority said yes
    //     uint yea;               // Number of Tokens in favor of the proposal; updated upon each yea vote
    //     uint nay;               // Number of Tokens opposed to the proposal; updated upon each nay vote
    //     address creator;        // Address of the shareholder who created the proposal
    // }
    NFTManager public nftmanager;

    constructor(){
        nftmanager = new NFTManager("ZDAO", "ZD");
        tokens = address(nftmanager);
        curator = msg.sender;
        howToJoin = "be happy";
        purpose = "to spread happyness";
        nftmanager.mintWithURI(msg.sender, "first");
    }
    //------------------------------------------------------------
    // These are all just public variables; some of which are set in the
    // constructor and never changed

    // Obtain a given proposal.   If one lists out the individual fields of
    // the Proposal struct, then one can just have this be a public mapping
    // (otherwise you run into problems with "Proposal memory"
    // versus "Proposal storage"
    //
    // @param i The proposal ID to obtain
    // @return The proposal for that ID
    // function proposals(uint i) external view override returns (address,uint,string memory,uint,bool,bool,uint,uint,address);
    mapping(uint => Proposal) public override proposals;
    // The minimum debate period that a generic proposal can have, in seconds;
    // this can be set to any reasonable for testing, but should be set to 10
    // minutes (600 seconds) for final submission.  This can be a constant.
    //
    // @return The minimum debating period in seconds
    // function minProposalDebatePeriod() external view returns (uint);
    uint constant public override minProposalDebatePeriod = 600;

    // NFT token contract address
    //
    // @return The contract address of the NFTManager (ERC-721 contract)
    // function tokens() external view returns (address);
    address public override tokens;

    // A string indicating the purpose of this DAO -- be creative!  This can
    // be a constant.
    //
    // @return A string describing the purpose of this DAO
    // function purpose() external view returns (string memory);
    string public override purpose;

    // Simple mapping to check if a shareholder has voted for it
    //
    // @param a The address of a member who voted
    // @param pid The proposal ID of a proposal
    // @return Whether the passed member voted yes for the passed proposal
    // function votedYes(address a, uint pid) external view returns (bool);
    mapping (address=>mapping (uint=>bool)) public override votedYes;

    // Simple mapping to check if a shareholder has voted against it
    //
    // @param a The address of a member who voted
    // @param pid The proposal ID of a proposal
    // @return Whether the passed member voted no for the passed proposal
    // function votedNo(address a, uint pid) external view returns (bool);
    mapping (address=>mapping (uint=>bool)) public override votedNo;
    // The total number of proposals ever created
    //
    // @return The total number of proposals ever created
    // function numberOfProposals() external view returns (uint);
    uint public override  numberOfProposals;

    // A string that states how one joins the DAO -- perhaps contacting the
    // deployer, perhaps some other secret means.  Make this something
    // creative!
    //
    // @return A description of what one has to do to join this DAO
    // function howToJoin() external view returns (string memory);
    string public override howToJoin;
    

    // This is the amount of ether (in wei) that has been reserved for
    // proposals.  This is increased by the proposal amount when a new
    // proposal is created, thus "reserving" those ether from being spent on
    // another proposal while this one is still being voted upon.  If a
    // proposal succeeds, then the proposal amount is paid out.  In either
    // case, once the voting period for the proposal ends, this amount is
    // reduced by the proposal amount.
    //
    // @return The amount of ether, in wei, reserved for proposals
    // function reservedEther() external view returns (uint);
    uint public override reservedEther;

    // Who is the curator (owner / deployer) of this contract?
    //
    // @return The curator (deployer) of this contract
    // function curator() external view returns (address);
    address public override curator;
    //------------------------------    ------------------------------
    // Functions to implement

    // This allows the function to receive ether without having a payable
    // function -- it doesn't have to have any code in its body, but it does
    // have to be present.
    receive() external override payable {
    // Function body can be empty if you don't need to execute any logic upon receiving Ether
    }

    // `msg.sender` creates a proposal to send `_amount` Wei to `_recipient`
    // with the transaction data `_transactionData`.  This can only be called
    // by a member of the DAO, and should revert otherwise.
    //
    // @param recipient Address of the recipient of the proposed transaction
    // @param amount Amount of wei to be sent with the proposed transaction
    // @param description String describing the proposal
    // @param debatingPeriod Time used for debating a proposal, at least
    //        `minProposalDebatePeriod()` seconds long.  Note that the 
    //        provided parameter can *equal* the `minProposalDebatePeriod()` 
    //        as well.
    // @return The proposal ID
    function newProposal(address recipient, uint amount, string memory description, 
                          uint debatingPeriod) external payable override returns (uint){
        require(isMember(msg.sender), "Only members can propose");
        require(debatingPeriod >= minProposalDebatePeriod, "Debating period too short");
        require(address(this).balance >= reservedEther + amount, "Insufficient funds");
        

        uint proposalID = numberOfProposals++;
        Proposal storage p = proposals[proposalID];
        p.recipient = recipient;
        p.amount = amount;
        p.description = description;
        p.votingDeadline = block.timestamp + debatingPeriod;
        p.open = true;
        p.creator = msg.sender;

        reservedEther += amount;

        emit NewProposal(proposalID, recipient, amount, description);
        return proposalID;
                          }

    // Vote on proposal `_proposalID` with `_supportsProposal`.  This can only
    // be called by a member of the DAO, and should revert otherwise.
    //
    // @param proposalID The proposal ID
    // @param supportsProposal true/false as to whether in support of the
    //        proposal
    function vote(uint proposalID, bool supportsProposal) override external{
        require(isMember(msg.sender), "Only members can propose");
        require(proposals[proposalID].open, "Voting closed");
        require(block.timestamp <= proposals[proposalID].votingDeadline, "Voting period has ended");
        require(!votedYes[msg.sender][proposalID] && !votedNo[msg.sender][proposalID], "Already voted");

        if(supportsProposal){
            proposals[proposalID].yea ++;
            votedYes[msg.sender][proposalID] = true;
        }else{
            proposals[proposalID].nay++;
            votedNo[msg.sender][proposalID] = true;
        }

        emit Voted(proposalID, supportsProposal, msg.sender);
    }

    // Checks whether proposal `_proposalID` with transaction data
    // `_transactionData` has been voted for or rejected, and transfers the
    // ETH in the case it has been voted for.  This can only be called by a
    // member of the DAO, and should revert otherwise.  It also reverts if
    // the proposal cannot be closed (time is not up, etc.).
    //
    // @param proposalID The proposal ID
    function closeProposal(uint proposalID) override external{
        require(isMember(msg.sender), "Only members can close proposals");
        require(proposals[proposalID].open, "Voting already closed");
        require(block.timestamp >= proposals[proposalID].votingDeadline, "Voting period not over");

        Proposal storage p = proposals[proposalID];

        p.open = false;
        if(p.nay<p.yea){
            p.proposalPassed = true;
            (bool sent, ) = p.recipient.call{value: p.amount}("");
            require(sent, "Failed to send Ether");
        }

        reservedEther-= p.amount;

        emit ProposalClosed(proposalID, p.proposalPassed);
    }

    // Returns true if the passed address is a member of this DAO, false
    // otherwise.  This likely has to call the NFTManager, so it's not just a
    // public variable.  For this assignment, this should be callable by both
    // members and non-members.
    //
    // @param who An account address
    // @return A bool as to whether the passed address is a member of this DAO
    function isMember(address who) public view override returns (bool){
        return nftmanager.balanceOf(who) > 0;
    }

    // Adds the passed member.  For this assignment, any current member of the
    // DAO can add members. Membership is indicated by an NFT token, so one
    // must be transferred to this member as part of this call.  This can only
    // be called by a member of the DAO, and should revert otherwise.
    // @param who The new member to add
    //
    // @param who An account address to have join the DAO
    function addMember(address who) external override {
        require(isMember(msg.sender), "Only members can add members");
        require(!isMember(who), "Already a member");
        // string memory uri = substring(Strings.toHexString(who),2,34);
        nftmanager.mintWithURI(who, "uri");  // Assuming mint function takes (address, tokenId)
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++)
            result[i-startIndex] = strBytes[i];
        return string(result);
    }
    // This is how one requests to join the DAO.  Presumably they called
    // howToJoin(), and fulfilled any requirement(s) therein.  In a real
    // application, this would put them into a list for the owner(s) to
    // approve or deny.  For our uses, this will automatically allow the
    // caller (`msg.sender`) to be a member of the DAO.  This functionality
    // is for grading purposes.  This function should revert if the caller is
    // already a member.
    function requestMembership() external override {
        require(!isMember(msg.sender), "Already a member");
        string memory uri = substring(Strings.toHexString(msg.sender),2,34);
        nftmanager.mintWithURI(msg.sender, uri);  // Assuming mint function takes (address, tokenId)
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IDAO).interfaceId;
    }
}