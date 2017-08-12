pragma solidity ^0.4.15;

contract EightBallModel {
    string public constant name = "EightBallModel";
    string public constant symbol = "EBM";
    uint8 public constant decimals = 0;

    address owner;

    struct Participant {
        uint level;
        address[2] children;
        address parent;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => Participant) participants;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function EightBallModel() {
        owner = msg.sender;
        balances[msg.sender] = 999999999999;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     function transfer(address _to, uint256 _amount) returns (bool success) {
         require(balances[msg.sender] >= _amount);
         require(_amount > 0);
         require(balances[_to] + _amount > balances[_to]);
         balances[msg.sender] -= _amount;
         balances[_to] += _amount;
         Transfer(msg.sender, _to, _amount);
         return true;
     }

     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         return true;
     }

     function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
         require(_amount > 0);
         require(balances[_from] >= _amount);
         require(allowed[_from][msg.sender] >= _amount);
         require(balances[_to] + _amount > balances[_to]);

         balances[_from] -= _amount;
         allowed[_from][msg.sender] -= _amount;
         balances[_to] += _amount;
         return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint remaining) {
         return allowed[_owner][_spender];
     }

     // token costs 0.01 ether
     // multiple tokens can be bought at the same time
     function join(address _referrer) public payable returns (bool) {
         //check
         require(_referrer != msg.sender);
         require(participants[_referrer].level > 0);
         require(participants[_referrer].children[0] == 0x0
            || participants[_referrer].children[1] == 0x0)

         // action
         uint256 amountTokens = tokensFromWei(msg.value);
         balances[msg.sender] = amountTokens;

         if (participants[_referrer].children[0] == 0x0) {
             participants[_referrer].children[0] = msg.sender;
             participants[_referrer].level += 1;
         } else {
             participants[_referrer].children[1] = msg.sender;
         }

         return true;
     }

     function tokensFromWei(uint256 ) internal constant returns (uint256 _amountWei) {
         require(_amountWei > FACTOR);
         uint256 FACTOR = 10000000000000000;
         return _amountWei / FACTOR;
     }

     function closeDown() public {
         require(owner == msg.sender)
         selfdestruct(owner);
     }

}
