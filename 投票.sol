// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Ownable.sol';
import './Counters.sol';
import './ERC20.sol';

contract VotingContract is ERC20, Ownable {
    using Counters for Counters.Counter;

    // 定义候选人结构体
    struct Candidate {
        string name;
        string describe;
        uint256 voteCount;
        address[] voters;
    }

    // 记录是否已投票
    mapping(address => bool) private hasVoted;
    uint256 private totalVotes;

    // 存储投票选项
    mapping(uint256 => Candidate) public candidates;
    Counters.Counter private candidateCounter;

    // 投票状态
    bool public votingOpen;

    // 投票结束
    event VotingEnded(uint256 winnerId, string winnerName);
    // 投票
    event VoteCasted(address voter, uint256 candidateId);
    //积分奖励
    constructor() ERC20('Jifen', 'JF') {
        _mint(msg.sender, 2100000);
        votingOpen = true;
    }

    // 添加投票选项人
    function addCandidate(string memory name,string memory describe) public onlyOwner {
        candidateCounter.increment();
        uint256 candidateId = candidateCounter.current();
        candidates[candidateId].name = name;
        candidates[candidateId].describe = describe;
        candidates[candidateId].voteCount = 0;
    }

    // 投票
    function vote(uint256 candidateId) public {
        require(votingOpen, 'Voting is not open');
        require(!hasVoted[msg.sender], 'You have already voted');
        require(
            candidateId <= candidateCounter.current(),
            'Invalid candidate ID'
        );
        candidates[candidateId].voters.push(msg.sender);
        candidates[candidateId].voteCount++;
        hasVoted[msg.sender] = true;
        totalVotes++;
        emit VoteCasted(msg.sender, candidateId);
    }

    // 关闭投票
    function endVoting() public onlyOwner {
        require(votingOpen, 'Voting is not open');

        uint256 winnerId = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 1; i <= candidateCounter.current(); i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerId = i;
            }
        }
        votingOpen = false;

        // 奖励投票正确的地址
        address[] memory winner = candidates[winnerId].voters;
        for (uint256 i = 0; i < winner.length; i++) {
            _transfer(msg.sender, winner[i], 1000);
        }

        emit VotingEnded(winnerId, candidates[winnerId].name);
    }

    // 开启新投票
    function reopenVoting() public onlyOwner {
        require(!votingOpen, 'Voting is already open');

        // 清空投票记录和投票选项
        for (uint256 i = 1; i <= candidateCounter.current(); i++) {
            address[] memory voters = candidates[i].voters;
            for (uint256 k = 0; k < voters.length; k++) {
                // 清空用户投票状态
                delete hasVoted[voters[k]];
            }

            delete candidates[i];
        }
        candidateCounter.reset();
        votingOpen = true;
    }
}
