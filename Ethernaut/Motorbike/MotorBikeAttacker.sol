pragma solidity <0.7.0;

contract EngineDestroyer {

    constructor() public {}

    function destroy() public {
        selfdestruct(address(0));
    }
}