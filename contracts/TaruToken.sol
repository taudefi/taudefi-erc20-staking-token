pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "./TConst.sol";
import "./IProveOfStake.sol";
import "./ProveOfStake.sol";

contract TaruToken is ERC20Capped, TConst {
    //uint8 private _decimal = 8;
    uint8 private _decimal = 0;
    bool private _initialize = false;
    uint256 private _maxSupply = 250000000000;
    bool private _locked;
    string constant tokenName                   = "Tau Defi";
    string constant tokenSymbol                 = "TARU";
    
    //uint256 public constant BASE_DIFFICULTY     = 730;
    //uint32 public constant TIME_PER_BLOCK       = 86400;
    uint256 public constant BASE_DIFFICULTY     = 60;
    uint32 public constant TIME_PER_BLOCK       = 60;
    
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
    ERC20(tokenName, tokenSymbol)
    ERC20Capped(_maxSupply * 10**_decimal)
    {
        //_setupDecimals(_decimal);
        //super._mint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2500 * 10**_decimal);
        //super._mint(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 2500 * 10**_decimal);
    }
    
    function initialize() external
    {
        require(_initialize == false, "ERR_INITIALIZED");
        _mineable = ((_maxSupply * 19)/100) * 10**_decimal;
        _claimed_epoch_time = block.timestamp;
        _proveOfStakeAddr = address(new ProveOfStake(address(this)));
        super._mint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 2500 * 10**_decimal);
        super._mint(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 2500 * 10**_decimal);
        _initialize = true;
    }
    
    function burn(uint256 amount) external returns (bool)
    {
        super._burn(msg.sender, amount);
        _mineable += amount;
        return true;
    }
    
    function claimReward() external noReentrant returns (uint256){
        (uint256 _availableReward, uint256 unclaimedEpoch) = availableReward();
        if(_availableReward > 0){
            super._mint(_proveOfStakeAddr, _availableReward);
            _mineable = _mineable - _availableReward;
            _claimed_epoch_time = block.timestamp;
            _claimed_epoch = _claimed_epoch + unclaimedEpoch;
            //IProveOfStake(_proveOfStakeAddr).distributeRewards(_availableReward);
            return _availableReward;
        }
        return 0;
    }
    
    function adjustDifficulty() public view returns (uint256 rarity, uint256 unclaimedEpoch) {
        uint256 _epoch_time_diff = block.timestamp - _claimed_epoch_time;
        unclaimedEpoch = _epoch_time_diff / TIME_PER_BLOCK;
        if(unclaimedEpoch > BASE_DIFFICULTY){
            //return BONE;
            rarity = BONE;
        }else{
            rarity = (unclaimedEpoch * BONE) / BASE_DIFFICULTY;
        }
        //return (unclaimedEpoch * BONE) / BASE_DIFFICULTY;
    }
    
    function availableReward() public view returns (uint256 reward, uint256 unclaimedEpoch) {
        (uint256 rarity, uint256 _unclaimedEpoch) = adjustDifficulty();
        reward = (_mineable * rarity) / BONE;
        unclaimedEpoch = _unclaimedEpoch;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }
    
    function getNow() public view returns (uint256) {
        return block.timestamp;
    }
} 