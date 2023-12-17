// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    address public admin;
    enum ElectionState { NOT_STARTED, ONGOING, ENDED }
    ElectionState public electionState;

    struct Candidate {
        uint256 id;
        string name;
        string proposal;
        uint256 votes;
    }

    struct Voter {
        address voterAddress;
        string name;
        uint256 votedFor;
        bool hasDelegated;
        address delegate;
    }

    Candidate[] public candidates;
    mapping(address => Voter) public voters;
    mapping(address => bool) public registeredVoters;

    event NewCandidate(uint256 indexed id, string name, string proposal);
    event NewVoter(address indexed voterAddress, string name);
    event ElectionStarted();
    event Voted(address indexed voterAddress, uint256 candidateId);
    event ElectionEnded();
    event Delegate(address indexed delegator, address indexed delegatee);
    event Winner(string name, uint256 id, uint256 votes);
    event ElectionResult(uint256 id, string name, uint256 votes);

    constructor() {
        admin = msg.sender;
        electionState = ElectionState.NOT_STARTED;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyRegisteredVoter() {
        require(registeredVoters[msg.sender], "Only registered voters can call this function");
        _;
    }

    modifier electionInProgress() {
        require(electionState == ElectionState.ONGOING, "Election is not in progress");
        _;
    }

    modifier hasNotVoted() {
        require(voters[msg.sender].votedFor == 0, "You have already voted");
        _;
    }

    modifier canDelegate() {
        require(electionState == ElectionState.ONGOING, "Election is not in progress");
        require(!voters[msg.sender].hasDelegated, "You have already delegated your vote");
        _;
    }

    function addCandidate(string memory _name, string memory _proposal, address owner) public onlyAdmin {
        require(owner == admin);
        require(electionState == ElectionState.NOT_STARTED, "Cannot add candidates once the election has started");
        uint256 candidateId = candidates.length + 1;
        candidates.push(Candidate(candidateId, _name, _proposal, 0));
        emit NewCandidate(candidateId, _name, _proposal);
    }

    function addVoter(address _voter, address owner) public onlyAdmin {
        require(owner == admin);
        require(electionState == ElectionState.NOT_STARTED, "Cannot add voters once the election has started");
        require(!registeredVoters[_voter], "Voter already registered");
        registeredVoters[_voter] = true;
        voters[_voter] = Voter(_voter, "", 0, false, address(0));
        emit NewVoter(_voter, "");
    }

    function startElection(address owner) public onlyAdmin {
        require(owner == admin);
        require(electionState == ElectionState.NOT_STARTED, "Election has already started or ended");
        electionState = ElectionState.ONGOING;
        emit ElectionStarted();
    }

    function displayCandidateDetails(uint256 _candidateId) public view returns (uint256 id, string memory name, string memory proposal) {
        require(_candidateId > 0 && _candidateId <= candidates.length, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId - 1];
        return (candidate.id, candidate.name, candidate.proposal);
    }

    function showWinner() public view returns (string memory name, uint256 id, uint256 votes) {
        require(electionState == ElectionState.ENDED, "Election is not over yet");
        uint256 winnerId = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].votes > maxVotes) {
                maxVotes = candidates[i].votes;
                winnerId = candidates[i].id;
            }
        }

        Candidate memory winner = candidates[winnerId - 1];
        return (winner.name, winner.id, winner.votes);
    }

    function delegateVotingRight(address delegatee, address voterAddress) public canDelegate {
        require(delegatee != voterAddress, "You cannot delegate your vote to yourself");
        require(registeredVoters[delegatee], "Delegate address is not a registered voter");
        voters[voterAddress].hasDelegated = true;
        voters[voterAddress].delegate = delegatee;
        emit Delegate(voterAddress, delegatee);
    }

    function castVote(uint256 _candidateId, address voterAddress) public onlyRegisteredVoter electionInProgress hasNotVoted {
        require(_candidateId > 0 && _candidateId <= candidates.length, "Invalid candidate ID");
        require(voters[voterAddress].hasDelegated == false, "You cannot vote, as you have delegated your vote");
        candidates[_candidateId - 1].votes++;
        voters[voterAddress].votedFor = _candidateId;
        emit Voted(voterAddress, _candidateId);
    }

    function endElection(address owner) public onlyAdmin electionInProgress {
        require(owner == admin);
        electionState = ElectionState.ENDED;
        emit ElectionEnded();
    }

    function showElectionResults(uint256 _candidateId) public view returns (uint256 id, string memory name, uint256 votes) {
        require(_candidateId > 0 && _candidateId <= candidates.length, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId - 1];
        return (candidate.id, candidate.name, candidate.votes);
    }

    function viewVoterProfile(address _voterAddress) public view returns (string memory name, uint256 votedFor, bool hasDelegated) {
        Voter memory voter = voters[_voterAddress];
        return (voter.name, voter.votedFor, voter.hasDelegated);
    }
}

