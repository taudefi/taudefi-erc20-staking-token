pragma solidity ^0.8.0;

interface IStakeholder{
    function rate() external view returns (uint256);
    function active() external view returns (bool);
}