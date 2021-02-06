pragma solidity =0.7.4;

contract VEIS_DATA {
    string public standard = 'veis.io';
    string public name = 'VEIS';
    string public symbol = 'VS';
    uint8 public decimals = 18;
    uint256 public totalSupply = 900000 ether;
    uint256 public maxLeval=631;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    address public admin;
    address public computeContract;
    
    struct SYSTEM{
        uint256 StarAngel;
        uint256 StarLeval;
        uint256 maxAirDrop;
        uint256 alreadyBuy;
        uint256 ObliterateTime;
    }
    struct USER{
        uint256 id;
        uint256 referee;
        uint256 grade;
        bool Airdrop;
        uint256 totalInputEth;
    }
    
    constructor () {
        admin=msg.sender;        
    }
    function set_old_user(address addr,uint256 id,uint256 referee,uint256 grade,bool Airdrop,uint256 totalInputEth,uint256 b)internal{
        USER memory u;
        u.id=id;
        u.referee = referee;
        u.grade =grade;
        u.Airdrop =Airdrop;
        u.totalInputEth = totalInputEth;
        balanceOf[addr]=b;
        StarAngels[addr]=u;
        if(u.id>0)StarAngelID[u.id]=addr;
        
    }
    modifier OnlyCompute() {
        require(msg.sender == computeContract,'only compute Contract');
        _;
    }
    function setSystem(uint256 angel,uint256 leval,uint256 max,uint256 alBuy,uint256 obl,uint256 totalVeis)public OnlyCompute{
        sys.StarAngel=angel;
        sys.StarLeval=leval;
        sys.maxAirDrop=max;
        sys.alreadyBuy=alBuy;
        sys.ObliterateTime = obl;
        totalSupply = totalVeis;
    }
    function setUser(address addr,uint256 id,uint256 referee,uint256 grade,bool airdrop,uint256 totaleth,uint256 balan)public OnlyCompute{
        USER storage u=StarAngels[addr];
        u.id=id;
        u.referee=referee;
        u.grade=grade;
        u.Airdrop=airdrop;
        u.totalInputEth=totaleth;
        if(id>0)StarAngelID[id]=addr;
        if(balan >0)balanceOf[addr]=balan;
    }
    function setCompute(address compute)public{
        require(computeContract==address(0x0));
        computeContract =compute;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to !=address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /*******************************************************************************************/
    mapping(address =>USER)public StarAngels;
    mapping(uint256 =>address)public StarAngelID;
    SYSTEM public sys;
    function issue(address addr,uint256 value)public OnlyCompute returns(uint256 ret){
        uint256 v=value;
        require(totalSupply + v > totalSupply,'totalSupply + v > totalSupply');
        totalSupply += v;
        balanceOf[addr]+=v;
        return v;
    }
    function deleteVies(address addr,uint256 value)external OnlyCompute returns(bool ret){
        require(balanceOf[addr] >= value,'Insufficient vies');
        balanceOf[addr] -= value;
        balanceOf[admin]+= (value /5);
        totalSupply -= (value/5*4);
        return true;
    }
    function sendAirdrop(address addr,uint256 value) external OnlyCompute returns(bool ret){
        require(value <= sys.maxAirDrop,'Airdrop has been released over');
        USER storage u=StarAngels[addr];
        u.Airdrop =true;
        issue(addr,value);
        sys.maxAirDrop -= value;
        return true;
    }
    function addAlreadyBuy(address user,uint256 addValue,uint256 eth) external OnlyCompute{
        require(sys.alreadyBuy + addValue > sys.alreadyBuy);
        sys.alreadyBuy += addValue;
        StarAngels[user].totalInputEth += eth;
    }
    function upDataObliterateTime() external OnlyCompute{
        sys.ObliterateTime = block.timestamp;
    }
    function setNextLeval()external OnlyCompute returns(uint256 leval){
        if(sys.StarLeval == maxLeval)return 0;
        sys.StarLeval++;
        sys.alreadyBuy = 0;
        if(sys.StarLeval % 50 == 0) sys.ObliterateTime = block.timestamp;
    }
    function setReferee(address user,uint256 referee)external OnlyCompute returns(uint256 ret){
        StarAngels[user].referee = referee;
        return referee;
    }
    function BecomeStarAngel(address user,uint256 referee,uint256 grade)external OnlyCompute returns(uint256 id,uint256 refree){
        USER storage u =StarAngels[user];
        if(u.id==0){
            StarAngelID[++sys.StarAngel]=user;
            u.referee = referee;
            u.id = sys.StarAngel;
        }
        if(grade <= u.grade)return (0,0);
        u.grade = grade;
        return (u.id,u.referee);
    }
}

contract VEIS_COMPUTE{
    VEIS_DATA public veisContract;
    address payable ColdPurse;
    uint256[5] public airCount=[uint256(10000),15000,20000,15000,10000];
    
    address admin;
    event OnAirDrop(address indexed addr,uint256 value);
    event OnBecomeStarAngel(address indexed user,uint256 InputETH,uint256 id,uint256 refe);
    event OnAllotETH(address indexed user,address indexed sour,uint256 eth);
    event OnDerivation(address indexed user,uint256 InputETH,uint256 OutPutVies,uint256 refe);
    event OnObliterate(address indexed user,uint256 eth,uint256 vies);
    event OnNextLeval(uint256 newLeval);
    struct SYSTEM{
        uint256 StarAngel;
        uint256 StarLeval;
        uint256 maxAirDrop;
        uint256 alreadyBuy;
        uint256 ObliterateTime;
    }
    struct USER{
        uint256 id;
        uint256 referee;
        uint256 grade;
        bool Airdrop;
        uint256 totalInputEth;
    }
    fallback()external payable{}
    receive()external payable{}
    
    constructor () {
        admin=msg.sender;
    }
    
    
    function setColdPurse(address addr)public{
        require(ColdPurse == address(0x0),'only first');
        ColdPurse = payable(addr);
    }
    function setDataComtrct(address addr)public{
        require(veisContract==address(0x0),'only first');
        veisContract = VEIS_DATA(addr);
    }

    function allotETH(address addr,uint256 value,uint256 referee)internal{
        USER memory u;
        uint256 id=referee;
        address star;
        uint256 allot;
        uint256 eth = value;
        uint256 allallot;
        for(uint8 i=0;i<3;i++){
            star = veisContract.StarAngelID(id);
            (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(star);
            if(u.grade == 1)allot = 8;
            else if(u.grade == 2) allot = 10;
            else if(u.grade == 3) allot =12;
            else if(u.grade == 4) allot = 16;
            else if(u.grade == 5) allot =20;
            
            allot=eth * allot /100;
            emit OnAllotETH(star,addr,allot);
            allallot+=allot;
            payable(star).transfer(allot);
            id=u.referee;
            if(id == 0)break;
            eth = eth / 2;
        }

        require(allallot < value);
        ColdPurse.transfer(value - allallot);
    }

    function air_drop()public{
        USER memory u;
        (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(msg.sender);
        SYSTEM memory s;
        (s.StarAngel,s.StarLeval,s.maxAirDrop,s.alreadyBuy,s.ObliterateTime)=veisContract.sys();
        
        require(!u.Airdrop,'already received airdrop');
        uint256 eth=msg.sender.balance;
        uint256 vies;
        uint8 leval;
        require(eth > 0.1 ether,'eth > 0.1 ether');
        
        if(eth >= 15 ether ){vies = 50 ether; leval = 4;}
        else if(eth>=10 ether){vies = 30 ether;leval = 3;}
        else if(eth >=5 ether){vies = 20 ether;leval = 2;}
        else if(eth>=2 ether){vies = 10 ether;leval = 1;}
        else if(eth >=0.1 ether){vies = 5 ether;}
        
        require(s.maxAirDrop > vies,'Airdrop has been released over');
        require(airCount[leval]-- >1,'Airdrop has been over of this type');
        veisContract.sendAirdrop(msg.sender,vies);
        emit OnAirDrop(msg.sender,vies);
    }

    function Derivation(uint256 referee)public payable{
        require(msg.value > 0 ,'Eth cannot be 0');
        SYSTEM memory sys;
        (sys.StarAngel,sys.StarLeval,sys.maxAirDrop,sys.alreadyBuy,sys.ObliterateTime)=veisContract.sys();
        USER memory u;
        (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(msg.sender);
        if(u.referee == 0){
            require(referee > 0 && referee <= sys.StarAngel,'Incorrect recommendation code');
            u.referee = referee;
            veisContract.setReferee(msg.sender,referee);
        }
        uint256 eth = msg.value;
        uint256 price =6 + sys.StarLeval*2;
        
        uint256 LevalVies=uint256(sys.StarLeval) * (100 ether);
        require(sys.alreadyBuy < LevalVies,'Over total');
        uint256 vies = eth *100000 / price;
        if(vies + sys.alreadyBuy > LevalVies){
            vies = LevalVies - sys.alreadyBuy;
            eth = vies * price /100000;
            payable(msg.sender).transfer(msg.value - eth);
        }
        veisContract.addAlreadyBuy(msg.sender,vies,eth);

        allotETH(msg.sender,eth,u.referee);
        veisContract.issue(msg.sender,vies);
        emit OnDerivation(msg.sender,eth,vies,u.referee);
        if(vies + sys.alreadyBuy >= LevalVies){
            veisContract.setNextLeval();
            emit OnNextLeval(sys.StarLeval+1);
        }
    }
    event log(string  s , uint256 vLevalVies);

    function BecomeStarAngel(uint256 referee)public {
        USER memory u;
        (u.id,u.referee,u.grade,u.Airdrop,u.totalInputEth)=veisContract.StarAngels(msg.sender);
        uint256 eth = u.totalInputEth;
        require(eth >= 0.1 ether,'Become Star Angel eth less 0.1');
        uint256 grade;
        if(eth >= 10 ether)grade = 5;
        else if(eth >= 5 ether)grade = 4;
        else if(eth >= 1 ether) grade =3;
        else if(eth >= 0.5 ether)grade =2;
        else if(eth >=0.1 ether) grade = 1;
        
        uint256 refe;
        uint256 id;
        (id,refe)=veisContract.BecomeStarAngel(msg.sender,referee,grade);
        require(refe>0,'Incorrect references');
        emit OnBecomeStarAngel(msg.sender,eth,id,refe);
        
    }

    function Obliterate(uint256 value)public{
        require(value > 0,'Must be greater than 0');
        require(value <= veisContract.balanceOf(msg.sender),'Insufficient vies');
        SYSTEM memory sys;
        (sys.StarAngel,sys.StarLeval,sys.maxAirDrop,sys.alreadyBuy,sys.ObliterateTime)=veisContract.sys();
        
        require(sys.ObliterateTime + 86400 >= block.timestamp,'sys.ObliterateTime + 86400');
        uint256 leval=sys.StarLeval;
        if(leval %50 !=0){leval=leval /50 *50;}
        uint256 price = 6 +leval*2;
        uint256 eth = value /100000* price ;
        require(veisContract.deleteVies(msg.sender,value),'Vanishing failure');
        
        payable(msg.sender).transfer(eth);
        emit OnObliterate(msg.sender,eth,value);
    }
}










