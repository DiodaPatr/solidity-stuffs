// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ConstantSumAMM {

    IERC20 public immutable token0;
    IERC20 public immutable token1;
    uint256 public immutable FEE; // 10000 = 100% fee, 1 = 0.01% fee

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    // Events for logging purposes
    event Swap(address indexed swapper, address indexed tokenIn, uint256 indexed amount);
    event LiquidityAdded(address indexed adder, uint256 indexed amount0, uint256 indexed amount1);
    event LiquidityRemoved(address indexed remover, uint256 indexed amount0, uint256 indexed amount1);

    // Compared to require(), the errors use less bytecode, therefore more gas efficient
    // They are also easier to debug, and work with later on
    error NotEnoughLiquidity(uint256 amount, uint256 amountOut);
    error TokenNotInPool(address token);
    error ZeroSwap();
    error ZeroShares();
    error InvalidShares(address sender, uint256 amount);
    error InvalidFee(uint256 fee);
    error InvalidSupply();

    constructor(address _token0, address _token1, uint256 _FEE) {
        if(_FEE > 10000) { revert InvalidFee(_FEE); }
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        FEE = _FEE;
    }

    // Internal function that mints LP shares
    // TODO: ERC1155
    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    // Internal function that burns LP shares
    // TODO: ERC1155
    function _burn(address _from, uint256 _amount) private {
        if(totalSupply == 0) { revert InvalidSupply(); }

        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    // Swaps _amount number of _tokenIn to the other token in the pool
    // Since it is a constant sum pool, all swaps are 1:1
    // Reverts on unsupported token and 0 _amount, or if there is not enough liquidity
    function swap(address _tokenIn, uint256 _amount) external {
        if(_tokenIn != address(token0) && _tokenIn != address(token1)) { revert TokenNotInPool(_tokenIn); }
        if(_amount == 0) { revert ZeroSwap(); }

        uint256 amountOut;
        uint256 feeVal = (_amount * FEE) / 10000;
        if(FEE == 0 ) {
            amountOut = _amount;
        }
        else {
            amountOut = _amount - feeVal;
        }
        if(_tokenIn == address(token0)) {
            if(amountOut > reserve0){ revert NotEnoughLiquidity(_amount, amountOut); }
            reserve0 += _amount;
            reserve1 -= amountOut;
            token0.transferFrom(msg.sender, address(this), _amount);
            token1.transferFrom(address(this), msg.sender, amountOut);
        }
        else {
            if(amountOut > reserve1) { revert NotEnoughLiquidity(_amount, amountOut); }
            reserve1 += _amount;
            reserve0 -= amountOut;
            token1.transferFrom(msg.sender, address(this), _amount);
            token0.transferFrom(address(this), msg.sender, amountOut);
        }

        emit Swap(msg.sender, _tokenIn, _amount);
    }

    // Adds _amount0 of token0 and _amount1 of token1 to the pool,
    // receives proportional LP shares in return
    function addLiquidity(uint256 _amount0, uint256 _amount1) external {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));
        uint d0 = bal0 - reserve0;
        uint d1 = bal1 - reserve1;
        uint256 shares;

        if (totalSupply > 0) {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1);
        } 
        else {
            shares = d0 + d1;
        }

        if(shares < 0) { revert ZeroShares(); }
        _mint(msg.sender, shares);

        // Update the reserves
        reserve0 += _amount0;
        reserve1 += _amount1;

        emit LiquidityAdded(msg.sender, _amount0, _amount1);
    }

    // Removes liquidity in proportion to LP shares owned
    function removeLiquidity(uint256 _shares) external {
        //Can't remove liquidity, if there isn't any
        if(balanceOf[msg.sender] == 0) { revert ZeroShares(); }
        if(_shares > balanceOf[msg.sender]) { revert InvalidShares(msg.sender, _shares); }

        uint256 d0 = (reserve0 * _shares) / totalSupply;
        uint256 d1 = (reserve1 * _shares) / totalSupply;

        _burn(msg.sender, _shares);
        reserve0 -= d0;
        reserve1 -= d1;

        if(d0 > 0) {
            token0.transfer(msg.sender, d0);
        }

        if(d1 > 0) {
            token1.transfer(msg.sender, d1);
        }

        emit LiquidityRemoved(msg.sender, d0, d1);
    }

    function viewToken0() public view returns(address) {
        return address(token0);
    }

    function viewToken1() public view returns(address) {
        return address(token1);
    }

    function viewReserve0() public view returns (uint256) {
        return reserve0;
    }
    function viewReserve1() public view returns (uint256) {
        return reserve1;
    }
}