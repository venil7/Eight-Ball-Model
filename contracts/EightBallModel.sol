pragma solidity ^0.4.13;

contract EightBallModel {
    string public constant name = "EightBallModel";
    string public constant symbol = "EBM";
    uint8 public constant decimals = 18;

    uint256 TOKEN_FACTOR = 10000000000000000;
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
    event Payout(address indexed _captain);

    function EightBallModel() {
        uint256 LEVELS = 0xFFFF;
        owner = msg.sender;
        balances[msg.sender] = LEVELS;
        participants[msg.sender] = Participant({
            level: LEVELS,
            children: [address(0x0), address(0x0)],
            parent: address(0x0)
        });
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
         require(_referrer != address(0x0));
         require(_referrer != msg.sender);
         Participant storage referrer = participants[_referrer];
         require(hasNoChildren(referrer) || hasFirstChild(referrer));

         // action
         uint256 amountTokens = tokensFromWei(msg.value);
         balances[msg.sender] = amountTokens;

         // can only have 2 referrals,
         // fill them in sequentually, first then second
         uint index = hasNoChildren(referrer) ? 0 : 1;
         referrer.children[index] = msg.sender;

         Participant memory joiner = Participant({
             level: referrer.level - 1,
             parent: _referrer,
             children: [address(0x0), address(0x0)]
         });
         participants[msg.sender] = joiner;


         // get the potential CAPTAIN,
         // and check his team
         Participant storage copilot = participants[referrer.parent];
         Participant storage captain = participants[copilot.parent];
         if (captain.level > 0) {
             // we've got CAPTAIN
             // recursively calculate how many passengers they have
             uint CAPTAN_LEVEL = 3;
             uint NUM_PASSENGERS = 8;
             uint passengers = getNumberPassengers(copilot.parent, CAPTAN_LEVEL);
             // if there are all 8, pay the prize!
             if (passengers == NUM_PASSENGERS) {
                 if (copilot.parent.send(TOKEN_FACTOR * NUM_PASSENGERS)) {
                    Payout(_referrer);
                 }
             }
         }

         return true;
     }

     function hasNoChildren(Participant _participant) internal returns (bool) {
         return _participant.children[0] == address(0x0) &&
             _participant.children[1] == address(0x0);
     }

     function hasFirstChild(Participant _participant) internal returns (bool) {
         return _participant.children[0] == address(0x0) &&
             _participant.children[1] != address(0x0);
     }

     function hasBothChildren(Participant _participant) internal returns (bool) {
         return _participant.children[0] != address(0x0) &&
             _participant.children[1] != address(0x0);
     }

     // typically run on a CAPTAIN to be,
     // returns number of passengers on level 0
     function getNumberPassengers(address _address, uint _depth) internal constant returns (uint) {
         if (_address == address(0x0))
            return 0;
         if (_depth == 0)
            return 1;

         Participant storage participant = participants[_address];
         return getNumberPassengers(participant.children[0], _depth - 1) +
                getNumberPassengers(participant.children[1], _depth - 1);
     }

     function tokensFromWei(uint256 _amountWei) internal constant returns (uint256) {
         require(_amountWei > TOKEN_FACTOR);
         return _amountWei / TOKEN_FACTOR;
     }

     function closeDown() public {
         require(owner == msg.sender);
         selfdestruct(owner);
     }

}
