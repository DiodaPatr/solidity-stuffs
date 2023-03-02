// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ConstantProductAutomatedMarketMaker is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public testTokenX;
  IERC20 public testTokenY;
  uint256 public reserveX;
  uint256 public reserveY;
  uint256 public constant FEE_MAX = 10000;
  uint256 public feePercent;
  uint256 public totalSupply;

  mapping(address => uint256) private _balances;
  
  event LiquidityAdded(address indexed provider, uint256 amountX, uint256 amountY);
  event LiquidityRemoved(address indexed provider, uint256 amountX, uint256 amountY);
  event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut, uint256 fee);
  event Transfer(address indexed to, address indexed from, uint256 amount);

  function initialize(
    address _testTokenX,
    address _testTokenY,
    uint256 _initialReserveX,
    uint256 _initialReserveY,
    uint256 _feePercent) public initializer {

    __UUPSUpgradeable_init();
    __Ownable_init();
    require(_testTokenX != _testTokenY, "Tokens must be distinct");
    testTokenX = IERC20(_testTokenX);
    testTokenY = IERC20(_testTokenY);
    reserveX = _initialReserveX;
    reserveY = _initialReserveY;
    feePercent = _feePercent;
  }

  function _mint(address account, uint256 amount) internal {

        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

  function _burn(address account, uint256 amount) internal {

        require(amount <= _balances[account], "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

  function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

  function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

  function getReserves() public view returns (uint256, uint256, uint256) {
    return (reserveX, reserveY, block.number);
  }

  function calculateExpected(uint256 amountIn, uint256 reserveX, uint256 reserveY) public view returns (uint256) {
    uint256 amountInWithFee = amountIn.mul(FEE_MAX.sub(feePercent)).div(FEE_MAX);
    uint256 numerator = amountInWithFee.mul(reserveY);
    uint256 denominator = reserveX.add(amountInWithFee);
    return numerator.div(denominator);
  }

  function addLiquidity(uint256 amountX, uint256 amountY) external nonReentrant {
    require(amountX > 0 && amountY > 0, "Cannot add 0 liquidity");
    uint256 liquidityMinted;
    if (totalSupply == 0) {
        liquidityMinted = sqrt(amountX.mul(amountY));
        _mint(msg.sender, liquidityMinted);
    } else {

        (uint256 reserveX, uint256 reserveY, ) = getReserves();
        uint256 dy = amountY.mul(reserveX).div(reserveY.add(amountY));
        uint256 dx = amountX.mul(reserveY).div(reserveX.add(amountX));
        require(dx <= amountX, "Slippage too high");
        require(dy <= amountY, "Slippage too high");
        liquidityMinted = sqrt(dx.mul(dy)).mul(totalSupply).div(sqrt(reserveX.add(amountX).mul(reserveY.add(amountY))));
        _mint(msg.sender, liquidityMinted);
        testTokenX.safeTransferFrom(msg.sender, address(this), amountX);
        testTokenY.safeTransferFrom(msg.sender, address(this), amountY);
        reserveX = reserveX.add(amountX);
        reserveY = reserveY.add(amountY);
    }
    emit LiquidityAdded(msg.sender, amountX, amountY);
  }

  function removeLiquidity(uint256 amount) external nonReentrant {
    require(amount > 0 && balanceOf(msg.sender) >= amount, "Cannot remove 0 liquidity");
    uint256 amountX = amount.mul(reserveX).div(totalSupply);
    uint256 amountY = amount.mul(reserveY).div(totalSupply);
    require(amountX > 0 && amountY > 0, "Slippage too high");
    _burn(msg.sender, amount);
    testTokenX.safeTransfer(msg.sender, amountX);
    testTokenY.safeTransfer(msg.sender, amountY);
    reserveX = reserveX.sub(amountX);
    reserveY = reserveY.sub(amountY);
    emit LiquidityRemoved(msg.sender, amountX, amountY);
  }

  function swapTokens(uint256 amountIn, uint256 amountOutMin) external nonReentrant {
    require(amountIn > 0 && amountOutMin > 0, "Cannot swap 0 tokens");
    require(testTokenX.balanceOf(msg.sender) >= amountIn, "Insufficient balance");
    (uint256 reserveX, uint256 reserveY, ) = getReserves();
    uint256 amountOut = calculateExpected(amountIn, reserveX, reserveY);
    require(amountOut >= amountOutMin, "Slippage too high");
    testTokenX.safeTransferFrom(msg.sender, address(this), amountIn);
    uint256 fee = amountOut.mul(feePercent).div(FEE_MAX);
    uint256 amountOutAfterFee = amountOut.sub(fee);
    testTokenY.safeTransfer(msg.sender, amountOutAfterFee);
    testTokenY.safeTransfer(owner(), fee);
    emit TokensSwapped(msg.sender, amountIn, amountOutAfterFee, fee);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}

