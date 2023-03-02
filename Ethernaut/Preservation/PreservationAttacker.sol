pragma solidity ^0.5.0;

contract Attacker {

    address one;
    address two;
    address owner;
    uint time;

    function setTime(uint _time) public {

        owner = msg.sender;
    }
}