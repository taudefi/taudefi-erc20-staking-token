pragma solidity ^0.8.0;
import "./TConst.sol";
import "./Stakeholder.sol";
import "./IERC20Staking.sol";
import "./IStakeholder.sol";

contract ProveOfStake is TConst {
    uint8 private _stakerThreshold = 6;
    address[] private stakeholders;
    address private _erc20StakingAddr;
    
    uint256 public _totalSupply;
    mapping(address => uint256) public _DP_balances;
    mapping(address => uint256) public _LP_balances;
    uint256 public _totalPointSupply;
    
    //uint256 public _rate;
    //mapping (address => uint256) public _h_balances;
    //uint256 public _h_totalSupply;
    //uint256 public _deposited_total;
    
    
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
        //_rate = 1 * BONE;
        
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
    
    function balanceOf(address pool)
        public view returns (uint256){
        return IERC20Staking(_erc20StakingAddr).balanceOf(pool);
    }
    
    function pointRate()
        public view returns (uint256){
        if(_totalSupply == 0 || _totalPointSupply == 0){
            return 1 * BONE;
        }
        return (_totalSupply * BONE)/_totalPointSupply;
    }
    
    function pointBalanceOf(address account)
        public view returns (uint256){
        return _LP_balances[account];
    }
    
    //todo
    function distributeRewards(uint256 reward) external returns (bool){
        uint256 totalDistributed = 0;
        for (uint i=0; i < stakeholders.length - 1; i++){
            if(IStakeholder(stakeholders[i]).active()){
                //totalDistributed = totalDistributed + _claimReward(stakeholders[i]);
            }
        }
        
        uint256 _burn = reward - totalDistributed;
        if(_burn > 0){
            IERC20Staking(_erc20StakingAddr).burn(_burn);
        }
        return true;
    }
    
    function stake(uint256 amount) external 
        //todo: stakeholderExists(msg.sender) 
        returns (bool){
        uint256 _mintedPoint = (amount * BONE)/pointRate();
        _LP_balances[msg.sender] = _LP_balances[msg.sender] + _mintedPoint;
        _DP_balances[msg.sender] = _DP_balances[msg.sender] + amount;
        
        _totalPointSupply = _totalPointSupply + _mintedPoint;
        _totalSupply = _totalSupply + amount;
        
        return true;
    }
    
    function unstake(uint256 amount) external 
        //todo: stakeholderExists(msg.sender) 
        returns (bool){
        claimReward(msg.sender);
        uint256 _burntPoint = (pointBalanceOf(msg.sender) * amount) / balanceOf(msg.sender);
        _LP_balances[msg.sender] = _LP_balances[msg.sender] - _burntPoint;
        _DP_balances[msg.sender] = _DP_balances[msg.sender] - amount;
        _totalSupply = _totalSupply - amount;
        _totalPointSupply = _totalPointSupply - _burntPoint;
        
        //bool xfer = ERC20(erc20).transfer(account, _burntPoint);
        //require(xfer, "ERR_ERC20_FALSE");
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
    
    function _addReward(uint256 amount) 
        private returns (bool){
        _totalSupply = _totalSupply + amount;    
    }
    
    function claimStakingReward() public returns (uint256){
        if(IERC20Staking(_erc20StakingAddr).availableReward() > 0){
            uint256 reward = IERC20Staking(_erc20StakingAddr).claimReward();
            _addReward(reward);
            return reward;
        }
        return 0;
    }
    
    function claimReward(address account) public returns (uint256){
        claimStakingReward();
        uint256 _claimable = ((pointBalanceOf(account) * pointRate()) / BONE) - balanceOf(account);
        uint256 _diffPointBalance = pointBalanceOf(account) - ((balanceOf(account) * BONE) / pointRate());
        _LP_balances[account] = (balanceOf(account) * BONE) / pointRate();
        _totalSupply = _totalSupply - _claimable;
        _totalPointSupply = _totalPointSupply - _diffPointBalance;
        
        bool xfer = IERC20Staking(_erc20StakingAddr).transfer(account, _claimable);
        require(xfer, "ERR_ERC20_FALSE");
        return _claimable;
    }
    
    function poolRewardOf(address addr)
        public view returns (uint256){
        //uint256 totalAmount = (_h_balances[addr] * _rate) / BONE;
        //uint256 originPoolBalance = IERC20Staking(_erc20StakingAddr).balanceOf(addr);
        //if(totalAmount < originPoolBalance){
        //    return 0;
        //}else{
        //    uint256 poolRate = IStakeholder(addr).rate();
        //    uint256 totalPoolReward = ((_h_balances[addr] * _rate) / BONE) - originPoolBalance;// ((_h_balances[account].mul(_rate)).div(_rate_decimal)).sub(originBalanceOf(account));  
        //    return (totalPoolReward * poolRate) / 1e2; 
        //}
    }
}