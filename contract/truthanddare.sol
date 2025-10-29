// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

contract TruthOrDare {
    struct Challenge {
        address player;
        string challengeType; // "Truth" or "Dare"
        string prompt;
        bool completed;
        uint256 reward; // in wei
    }

    uint256 public challengeCount;
    mapping(uint256 => Challenge) public challenges;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Allow the contract to receive ETH
    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Player submits a Truth or Dare challenge
    function submitChallenge(
        string calldata _type,
        string calldata _prompt
    ) external payable {
        require(msg.value >= 0.001 ether, "Need at least 0.001 ETH reward");
        require(
            keccak256(bytes(_type)) == keccak256("Truth") ||
            keccak256(bytes(_type)) == keccak256("Dare"),
            "Type must be 'Truth' or 'Dare'"
        );

        challengeCount += 1;

        challenges[challengeCount] = Challenge({
            player: msg.sender,
            challengeType: _type,
            prompt: _prompt,
            completed: false,
            reward: msg.value
        });
    }

    // Anyone can mark a challenge as completed (no verification yet)
    function completeChallenge(uint256 _id) external {
        require(_id > 0 && _id <= challengeCount, "Invalid challenge ID");
        Challenge storage c = challenges[_id];
        require(!c.completed, "Already completed");

        c.completed = true;

        // Send reward to whoever completes it
        (bool sent, ) = payable(msg.sender).call{value: c.reward}("");
        require(sent, "Failed to send reward");
    }

    // Owner can withdraw leftover funds
    function withdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");

        (bool sent, ) = payable(owner).call{value: _amount}("");
        require(sent, "Withdraw failed");
    }

    // View helper
    function getChallenge(uint256 _id)
        external
        view
        returns (
            address player,
            string memory challengeType,
            string memory prompt,
            bool completed,
            uint256 reward
        )
    {
        require(_id > 0 && _id <= challengeCount, "Invalid challenge ID");
        Challenge memory c = challenges[_id];
        return (c.player, c.challengeType, c.prompt, c.completed, c.reward);
    }
}
