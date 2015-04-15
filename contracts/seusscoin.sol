contract SeussCoin { 
  address public owner;
  uint public initialFreeAmount;
  uint public defaultFreeAmount;
  mapping (address => uint) public balance;
  mapping (address => uint) public lastFreeRequest;

  function SeussCoin() {
    initialFreeAmount = 5;
    defaultFreeAmount = 1;
    owner = msg.sender;
    balance[owner] = 20000;
  }

  function sendCoin(address receiver, uint amount) returns(bool sufficient) {
    return moveCoin(msg.sender, receiver, amount);
  }

  function requestFreeSeussCoin() returns(bool successful) {
    // Has the sender requested free SEUSSCOIN ever? No? Give them "a lot"
    if (lastFreeRequest[msg.sender] == 0) {
      lastFreeRequest[msg.sender] = block.number;
      return moveCoin(owner, msg.sender, initialFreeAmount);
    }

    // Has the sender requested free SEUSSCOIN within the last
    // day? No? Give them a little. This assumes 12 second block times, 
    // roughly 7200 blocks per day. Use signed ints to prevent wrapping.
    if (int256(lastFreeRequest[msg.sender]) <= int256(block.number) - 7200) {
      lastFreeRequest[msg.sender] = block.number;
      return moveCoin(owner, msg.sender, defaultFreeAmount);
    }

    return false;
  }

  // Administrative function.
  function updateFreeAmount(uint newInitialFreeAmount, uint newDefaultFreeAmount) returns(bool successful){
    if (msg.sender != owner) {
      return false;
    }

    initialFreeAmount = newInitialFreeAmount;
    defaultFreeAmount = newDefaultFreeAmount;
    return true;
  }

  // Private function for moving coin between accounts, to remove code duplication.
  function moveCoin(address sender, address receiver, uint amount) private returns(bool sufficient) {
    if (balance[sender] < amount) return false;
    balance[sender] -= amount;
    balance[receiver] += amount;
    return true;
  }
}