pragma solidity ^0.8.0;
import "./TConst.sol";
import "./Stakeholder.sol";
import "./IERC20Staking.sol";
import "./IStakeholder.sol";

contract ProveOfStake is TConst {
    uint8 private _stakerThreshold = 9;
    address[] private stakeholders;
    address private _erc20StakingAddr;
    
    uint256 public _rate;
    mapping (address => uint256) public _h_balances;
    uint256 public _h_totalSupply;
    uint256 public _deposited_total;
    mapping (address => bool) public isStakeholder;
    
    //uint64 public totalStakeholder;
    
    //mapping (uint64 =>  mapping (address => bool)) private stakeholders;
    
    
    /*
     *  Modifiers
     */
    //modifier stakeholderNotExists(address stakeholder) {
    //    require(!isStakeholder[stakeholder], "ERR_STAKEHOLDER_EXISTS"); 
    //    _;
    //}
    
    modifier stakeholderExists(address stakeholder) {
        require(isStakeholder[stakeholder], "ERR_NOT_VALID_STAKEHOLDER"); 
        _;
    }
    
    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }
    
    constructor(address erc20){
        _erc20StakingAddr = erc20;
        _rate = 1 * BONE;
        
        Stakeholder _stakeholder21 = new Stakeholder(true, 100, "TURA Staking 21 days");
        stakeholders.push(address(_stakeholder21));
        isStakeholder[address(_stakeholder21)] = true;
        Stakeholder _stakeholder14 = new Stakeholder(true, 75, "TURA Staking 14 days");
        stakeholders.push(address(_stakeholder14));
        isStakeholder[address(_stakeholder14)] = true;
        Stakeholder _stakeholder7 = new Stakeholder(true, 60, "TURA Staking 7 days");
        stakeholders.push(address(_stakeholder7));
        isStakeholder[address(_stakeholder7)] = true;
    }
    
    function distributeRewards(uint256 reward) external returns (bool){
        _deposited_total = _deposited_total + reward;
        _rate = (_deposited_total * BONE) / _h_totalSupply;
        uint256 totalDistributed = 0;
        for (uint i=0; i < stakeholders.length - 1; i++){
            if(IStakeholder(stakeholders[i]).active()){
                totalDistributed = totalDistributed + _claimReward(stakeholders[i]);
            }
        }
        
        uint256 _burn = reward - totalDistributed;
        if(_burn > 0){
            IERC20Staking(_erc20StakingAddr).burn(_burn);
            _deposited_total = _deposited_total - _burn;
            _rate = (_deposited_total * BONE) / _h_totalSupply;
        }
        return true;
    }
    
    function stake(uint256 amount) external 
        stakeholderExists(msg.sender) returns (bool){
        _deposited_total = _deposited_total + amount;
        _addHiddenToken(msg.sender, amount);
        return true;
    }
    
    function unstake(uint256 amount) external 
        stakeholderExists(msg.sender) returns (bool){
        //todo:check if reward>0 then claimReward
        IERC20Staking(_erc20StakingAddr).claimReward();
        _deposited_total = _deposited_total - amount;
        _removeHiddenToken(msg.sender, amount);
        return true;
    }
    
    function addStakeholder() external
    {
        require(stakeholders.length <= _stakerThreshold, "ERR_MAX_STAKEHOLDER");
        Stakeholder _stakeholder = new Stakeholder(true, 98, "TODO TURA Staking 21 days");
        stakeholders.push(address(_stakeholder));
        isStakeholder[address(_stakeholder)] = true;
    }
    
    function removeStakeholder(address _stakeholder) external
        stakeholderExists(_stakeholder)
        notNull(_stakeholder)
    {
        isStakeholder[address(_stakeholder)] = false;
        
        if(stakeholders[stakeholders.length - 1] == _stakeholder){
            stakeholders.pop();
        }else{
            for (uint i=0; i < stakeholders.length - 1; i++){
                if (stakeholders[i] == _stakeholder) {
                    stakeholders[i] = stakeholders[stakeholders.length - 1];
                    stakeholders.pop();
                    break;
                }
            }
        }
    }
    
    function getStakeholders()
        public view
        returns (address[] memory)
    {
        return stakeholders;
    }
    
    function _claimReward(address account) private returns (uint256){
        uint256 poolReward = poolRewardOf(account);
        if(poolReward > 0){
            //uint256 poolReward = ((_h_balances[account].mul(_rate)).div(_rate_decimal)).sub(originBalanceOf(account));
            IERC20Staking(_erc20StakingAddr).transfer(account, poolReward);
            //_mint(account, userReward);
        }
        return poolReward;
    }
    
    //function originBalanceOf(address account) public view returns (uint256) {
    //    return super.balanceOf(account);
    //}
    
    function poolRewardOf(address addr)
        public view returns (uint256){
        uint256 totalAmount = (_h_balances[addr] * _rate) / BONE;
        uint256 originPoolBalance = IERC20Staking(_erc20StakingAddr).balanceOf(addr);
        if(totalAmount < originPoolBalance){
            return 0;
        }else{
            uint256 poolRate = IStakeholder(addr).rate();
            uint256 totalPoolReward = ((_h_balances[addr] * _rate) / BONE) - originPoolBalance;// ((_h_balances[account].mul(_rate)).div(_rate_decimal)).sub(originBalanceOf(account));  
            return (totalPoolReward * poolRate) / 1e2; 
        }
    }
    
    function _addHiddenToken(address account, uint256 amount) private returns (bool){
        uint256 _h_amount= (amount * BONE)/_rate;
        _h_balances[account] = _h_balances[account] + _h_amount;
        _h_totalSupply = _h_totalSupply + _h_amount;
        return true;
    }
    
    function _removeHiddenToken(address account, uint256 amount) private returns (bool){
        uint256 _h_amount= (amount * BONE)/_rate;
        _h_balances[account] = _h_balances[account] - _h_amount;
        _h_totalSupply = _h_totalSupply - _h_amount;   
        return true;
    }
}