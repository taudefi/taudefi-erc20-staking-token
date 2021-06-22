pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TauToken is ERC20 {
    constructor (uint256 initialSupply) ERC20("TauDefi", "TARU"){
        _mint(msg.sender, initialSupply);
    }   
} 