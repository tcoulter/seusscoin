contract SeussCoin { 
  address owner;
  uint freeAmount;
  mapping (address => uint) balances;
  mapping (address => uint) lastFreeRequest;

  function SeussCoin() {
    freeAmount = 1;
    owner = msg.sender;
    balances[owner] = 20000;
  }

  function sendCoin(address receiver, uint amount) returns(bool sufficient) {
    return moveCoin(msg.sender, receiver, amount);
  }

  function requestFreeSeussCoin() returns(bool successful) {
    // Ensure the sender hasn't requested free SEUSSCOIN within the last
    // day. This assumes 12 second block times, roughly 7200 blocks per day.
    if (lastFreeRequest[msg.sender] > 0 && lastFreeRequest[msg.sender] <= block.number - 7200) {
      return moveCoin(owner, msg.sender, freeAmount);
    }

    return false;
  }

  function updateFreeAmount(uint newFreeAmount) returns(bool successful){
    if (msg.sender != owner) {
      return false;
    }

    freeAmount = newFreeAmount;
    return true;
  }

  // Private function for moving coin between accounts, to remove code duplication.
  function moveCoin(address sender, address receiver, uint amount) private returns(bool sufficient) {
    if (balances[msg.sender] < amount) return false;
    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    return true;
  }
}