pragma solidity ^0.8.0;

//todo: day la ERC20
contract Stakeholder {
    address public _proveOfStakeAddr;
    uint256 private _rate;
    string private _name;
    bool private _active;
    
    constructor(bool active, uint256 rate, string memory name){
        _active = active;
        _rate = rate;
        _name = name;
    }
    
    function rate() external view returns (uint256) {
        return _rate;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    function active() external view returns (bool) {
        return _active;
    }
}