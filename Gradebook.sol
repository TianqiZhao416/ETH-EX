// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "./IGradebook.sol";

contract Gradebook is IGradebook {
    address public instructor;

    constructor(){
        instructor = msg.sender;
    }
    

    struct Assignment {
        string name;
        uint maxScore;
    }


    mapping (uint => Assignment) public assignments;
    mapping (uint => bool) public hasAssignment;
    //------------------------------------------------------------
    // The following six methods are done for you automatically -- as long as
    // you make the appropriate variable public, then Solidity will create
    // the getter function for you
    // Returns whether the passed address has been designated as a
    // teaching assistant
    // function tas(address ta) external view returns (bool);
    mapping (address => bool) public override tas;

    // Returns the max score for the given assignment
    // function max_scores(uint id) external view returns (uint);
    mapping (uint => uint) public override max_scores;

    // Returns the name of the given assignment
    // function assignment_names(uint id) external view returns (string memory);
    mapping (uint => string) public override assignment_names;

    // Returns the score for the given assignment ID and the given
    // student
    // function scores(uint id, string memory userid) external view returns (uint);
    mapping (uint => mapping (string => uint)) public override scores;

    // Returns how many assignments there are; the assignments are
    // assumed to be indexed from 0
    // function num_assignments() external view returns (uint);
    uint public override num_assignments;

    // Returns the address of the instructor, who is the person who
    // deployed this smart contract
    // function instructor() external view returns (address);





    //to implement
    // Designates the passed address as a teaching assistant; re-designating
    // an address a TA does not do anything special (no revert).  ONLY the
    // instructor can designated TAs.
    function designateTA(address ta) public override {
        require(msg.sender==instructor, "you aren't the instructor");
        tas[ta] = true;
    }

    // Adds an assignment of the given name with the given maximum score.  It
    // should revert if called by somebody other than the instructor or an
    // already designated teaching assistant.  It does not check if an
    // assignment with the same name already exists; thus, you can have
    // multiple assignments with the same name (but different IDs).  It
    // returns the assignment ID.
    function addAssignment(string memory name, uint max_score) public override returns (uint){
        require(msg.sender==instructor || tas[msg.sender]==true, "you can't add an assignment");
        assignments[num_assignments] = Assignment(name, max_score);
        uint assignNum = num_assignments;
        num_assignments++;
        hasAssignment[assignNum] = true;
        max_scores[assignNum] = max_score;

        emit assignmentCreationEvent(assignNum);
        return assignNum;
    }
    // Adds the given grade for the given student and the given assignment.
    // This should revert if (a) the caller is not the instructor or TA, or
    // (b) the assignment ID is invalid, or (c) the score is higher than the
    // allowed maximum score.
    // function addGrade(string memory student, uint assignment, uint score) external;
    function addGrade(string memory student, uint assignment, uint score) public override {
        require(msg.sender==instructor || tas[msg.sender]==true, "you can't add a grade");
        require(score > 0, "Max score must be a positive integer");
        require(hasAssignment[assignment], "this assignment doesn't exist");
        require(score <= assignments[assignment].maxScore, "assignment score is over limit");
        scores[assignment][student] = score;

        emit gradeEntryEvent(assignment);

    }

    // Obtains the average of the given student's scores.  Each assignment is
    // weighted based on the number of points for that assignment.  So a 5/10
    // on one assignment and a 20/20 on another assignment would yield 25/30
    // points, or 83.33.  This returns 100 times that, or 8333.  Note that
    // the value is truncated, not rounded; so if the average were 16.67%, it
    // would return 1666.  A student with no grades entered should have an
    // average of 0.

    
    function getAverage(string memory student) external view override returns (uint) {
        uint totalScore = 0;
        uint maxScore = 0;
        for (uint i = 0; i < num_assignments; i++) {
            totalScore += scores[i][student];
            maxScore += assignments[i].maxScore;
        }

        if (maxScore == 0) {
            return 0;
        }

        uint average = (totalScore * 10000) / maxScore;
        return average;
    }


       

    // This function is how we are going to test your program -- we are going
    // to request TA access.  For this assignment, it will automatically make
    // msg.sender a TA, and has no effect if the sender is already a TA
    // (or instructor).  In reality, this would revert(), as only the
    // instructor (and other TAs) can make new TAs.
    function requestTAAccess() external override {
        tas[msg.sender] = true;
    }


    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IGradebook).interfaceId || interfaceId == 0x01ffc9a7;
    }
}
