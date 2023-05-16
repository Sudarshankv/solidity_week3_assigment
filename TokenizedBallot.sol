```ts
TokenizedBallot.sol:

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./MyToken.sol";

contract TokenizedBallot is AccessControl {
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;
    MyToken public token;

    // Mapping from voter to a proposal id
    mapping(address => uint) public votes;
    
    constructor(MyToken _token) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
    }

    function addProposal(string memory description) public onlyRole(DEFAULT_ADMIN_ROLE) {
        proposals.push(Proposal({
            description: description,
            voteCount: 0
        }));
    }

    function vote(uint proposalId) public onlyRole(VOTER_ROLE) {
        require(proposalId < proposals.length, "Invalid proposal");

        uint previousProposalId = votes[msg.sender];
        if(previousProposalId != proposalId) {
            // If voter changes their vote, subtract their power from the previous proposal
            if(previousProposalId != 0) {
                proposals[previousProposalId].voteCount -= token.getPastVotes(msg.sender, block.number - 1);
            }
            // Add voter's power to the new proposal
            proposals[proposalId].voteCount += token.getPastVotes(msg.sender, block.number - 1);
            votes[msg.sender] = proposalId;
        }
    }

    function grantVoterRole(address voter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VOTER_ROLE, voter);
    }

    function getVotePower(address voter) public view returns (uint256) {
        return token.getPastVotes(voter, block.number - 1);
    }

    function getProposal(uint proposalId) public view returns (string memory description, uint voteCount) {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount);
    }

    function delegateVotes(address delegatee) public onlyRole(VOTER_ROLE) {
        token.delegate(delegatee);
    }

}
```