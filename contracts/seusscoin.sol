contract SeussCoin { 
  address public owner;
  uint public freeAmount;
  mapping (address => uint) public balance;
  mapping (address => uint) public lastFreeRequest;

  function SeussCoin() {
    freeAmount = 1;
    owner = msg.sender;
    balance[owner] = 20000;
  }

  function sendCoin(address receiver, uint amount) returns(bool sufficient) {
    return moveCoin(msg.sender, receiver, amount);
  }

  function requestFreeSeussCoin() returns(bool successful) {
    // Ensure the sender hasn't requested free SEUSSCOIN within the last
    // day. This assumes 12 second block times, roughly 7200 blocks per day.
    if (lastFreeRequest[msg.sender] == 0 || lastFreeRequest[msg.sender] <= block.number - 7200) {
      return moveCoin(owner, msg.sender, freeAmount);
    }

    return false;
  }

  // Administrative function.
  function updateFreeAmount(uint newFreeAmount) returns(bool successful){
    if (msg.sender != owner) {
      return false;
    }

    freeAmount = newFreeAmount;
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