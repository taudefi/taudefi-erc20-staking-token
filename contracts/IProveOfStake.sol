pragma solidity ^0.8.0;

interface IProveOfStake {
    function distributeRewards(uint256 reward) external returns (bool);
    function stake(uint256 amount) external returns (bool);
}