pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "./TConst.sol";
import "./IProveOfStake.sol";
import "./ProveOfStake.sol";

contract TaruToken is ERC20Capped, TConst {
    uint8 private _decimal = 8;
    bool private _initialize = false;
    uint256 private _maxSupply = 250000000000;
    bool private _locked;
    
    //uint256 public constant BASE_DIFFICULTY     = 730;
    //uint32 public constant TIME_PER_BLOCK       = 86400;
    uint256 public constant BASE_DIFFICULTY     = 31536000/15;
    uint32 public constant TIME_PER_BLOCK       = 15;
    address public _proveOfStakeAddr;
    uint256 public _mineable;
    uint256 public _claimed_epoch;
    uint256 public _claimed_epoch_time;
    
    modifier noReentrant() {
        require(!_locked, "ERR_NO_RE_ENTRANCY");
            _locked = true;
        _;
        _locked = false;
    }
    
    constructor () 
    ERC20("TauDefi", "TARU")
    ERC20Capped(_maxSupply * 10**_decimal)
    {
        //_setupDecimals(_decimal);
        //super._mint(msg.sender, 250000000000);
    }
    
    function initialize() external
    {
        require(_initialize == false, "ERR_INITIALIZED");
        _mineable = ((_maxSupply * 19)/100) * 10**_decimal;
        _claimed_epoch_time = block.timestamp;
        _proveOfStakeAddr = address(new ProveOfStake(address(this)));
        _initialize = true;
    }
    
    function burn(uint256 amount) external returns (bool)
    {
        super._burn(msg.sender, amount);
        _mineable += amount;
        return true;
    }
    
    function claimReward() external noReentrant returns (uint256){
        //todo: check claim reward > 0
        uint256 _availableReward = availableReward();
        super._mint(_proveOfStakeAddr, _availableReward);
        _mineable = _mineable - _availableReward;
        IProveOfStake(_proveOfStakeAddr).distributeRewards(_availableReward);
        return _availableReward;
    }
    
    function getAdjustDifficulty() public view returns (uint256) {
        uint256 _epoch_time_diff = block.timestamp - _claimed_epoch_time;
        uint256 _not_claimed_epoch = _epoch_time_diff / TIME_PER_BLOCK;
        if(_not_claimed_epoch > BASE_DIFFICULTY){
            return BONE;
        }
        return (_not_claimed_epoch * BONE) / BASE_DIFFICULTY;
    }
    
    function availableReward() public view returns (uint256) {
        uint256 _difficulty = getAdjustDifficulty();
        return (_mineable * _difficulty) / BONE;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }
    
    function getNow() public view returns (uint256) {
        return block.timestamp;
    }
} 