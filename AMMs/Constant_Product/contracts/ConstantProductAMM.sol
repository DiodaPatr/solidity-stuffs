// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ConstantProductAMM {

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public immutable FEE;

    uint256 public totalSupply;
    mapping(address => uint) public balanceOf;

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
    error InvalidToken();

    constructor(address _token0, address _token1, uint256 _FEE) {
        if(_FEE > 10000) { revert InvalidFee(_FEE); }
        if(_token0 == address(0) || _token1 == address(0))
        { revert InvalidToken(); }

        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        FEE = _FEE;
    }

    //TODO _mint & _burn with ERC1155
    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function swap(address _tokenIn, uint256 _amountIn) external {
        if(_tokenIn != address(token0) && _tokenIn != address(token1))
        { revert TokenNotInPool(_tokenIn); }
        if(_amountIn == 0) { revert ZeroSwap(); }

        uint256 amountInMinusFee = (_amountIn * FEE) / 10000;

        // Check which token is getting swapped
        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) = isToken0
        ? (token0, token1, reserve0, reserve1)
        : (token1, token0, reserve1, reserve0);
        uint256 amountOut = (reserveOut * amountInMinusFee) / (reserveIn + amountInMinusFee);
        
        if(amountOut > reserveOut) { revert NotEnoughLiquidity(_amountIn, amountOut); }
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        tokenOut.transferFrom(address(this), msg.sender, amountOut);

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
    }

    function addLiquidity() external {}
    function removeLiquidity() external {}
    function getQoute() external view {}
    
}