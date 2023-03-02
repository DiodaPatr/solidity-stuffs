// SPDX-License-Identifier: MIT
const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');

describe("ConstantProductAutomatedMarketMaker", function () {
/*     import "chai";
    import "hardhat-deploy";
    import "hardhat-deploy-ethers";
    import "hardhat/console.sol";
     */
  let owner, alice, bob;
  let TestTokenX, TestTokenY;
  let ConstantProductAutomatedMarketMaker;

  const INITIAL_RESERVE_X = 300;
  const INITIAL_RESERVE_Y = 200;
  const FEE_PERCENT = 100;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    TestTokenX = await (await ethers.getContractFactory('TestTokenX', owner)).deploy("TestTokenX", "TTX");
    TestTokenY = await (await ethers.getContractFactory('TestTokenX', owner)).deploy("TestTokenY", "TTY");

    ConstantProductAutomatedMarketMaker = await upgrades.deployProxy(await ethers.getContractFactory("ConstantProductAutomatedMarketMaker", owner),
         [ TestTokenX.address, TestTokenY.address, INITIAL_RESERVE_X, INITIAL_RESERVE_Y, FEE_PERCENT],
         {kind: 'uups', initializer: 'initialize'});
    await ConstantProductAutomatedMarketMaker.deployed();

/*     await upgrades.admin.transferProxyAdminOwnership(owner.address);
    await upgrades.admin.connect(owner).acceptProxyAdmin();

    const ConstantProductAutomatedMarketMakerV2Contract = await ethers.getContractFactory("ConstantProductAutomatedMarketMaker");
    ConstantProductAutomatedMarketMakerV2 = await upgrades.upgradeProxy(ConstantProductAutomatedMarketMaker.address, ConstantProductAutomatedMarketMakerV2Contract); */
  });

  it("should add liquidity correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const amountX = 100;
    const amountY = 200;
    const liquidity = Math.sqrt(amountX * amountY);

    await TestTokenX.transfer(alice.address, amountX);
    await TestTokenY.transfer(alice.address, amountY);

    await TestTokenX.connect(alice).approve(AMM.address, amountX);
    await TestTokenY.connect(alice).approve(AMM.address, amountY);

    await AMM.connect(alice).addLiquidity(amountX, amountY);

    expect(await TestTokenX.balanceOf(AMM.address)).to.equal(amountX);
    expect(await TestTokenY.balanceOf(AMM.address)).to.equal(amountY);
    expect(await AMM.balanceOf(alice.address)).to.equal(liquidity);
    expect(await AMM.totalSupply()).to.equal(liquidity);
  });

  it("should remove liquidity correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const amountX = 100;
    const amountY = 200;
    const liquidity = Math.sqrt(amountX * amountY);

    await TestTokenX.transfer(alice.address, amountX);
    await TestTokenY.transfer(alice.address, amountY);

    await TestTokenX.connect(alice).approve(AMM.address, amountX);
    await TestTokenY.connect(alice).approve(AMM.address, amountY);

    await AMM.connect(alice).addLiquidity(amountX, amountY);

    await AMM.connect(alice).removeLiquidity(liquidity);

    expect(await TestTokenX.balanceOf(AMM.address)).to.equal(0);
    expect(await TestTokenY.balanceOf(AMM.address)).to.equal(0);
    expect(await AMM.balanceOf(alice.address)).to.equal(0);
    expect(await AMM.totalSupply()).to.equal(0);
  });

  it("should swap tokens correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const amountX = 100;
    const amountY = 200;
    const amountIn = 10;
    const fee = amountIn * FEE_PERCENT / FEE_MAX;

    await TestTokenX.transfer(alice.address, amountX);
    await TestTokenY.transfer(alice.address, amountY);

    await TestTokenX.connect(alice).approve(AMM.address, amountIn);
    await AMM.connect(alice).swapTokens(amountIn, 0);

    expect(await TestTokenX.balanceOf(alice.address)).to.equal(amountX - amountIn);
    expect(await TestTokenY.balanceOf(alice.address, AMM.address)).to.equal(amountIn);
    expect(await TestTokenY.balanceOf(alice.address)).to.equal(calculateExpected(amountIn, INITIAL_RESERVE_X, INITIAL_RESERVE_Y));
    expect(await TestTokenY.balanceOf(owner.address)).to.equal(fee);
  });

  it("should not allow adding 0 liquidity", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    await expect(AMM.addLiquidity(0, 0)).to.be.revertedWith("Cannot add 0 liquidity");
  });

  it("should not allow removing 0 liquidity", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    await expect(AMM.removeLiquidity(0)).to.be.revertedWith("Cannot remove 0 liquidity");
  });

  it("should not allow swapping 0 tokens", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    await expect(AMM.swapTokens(0, 0)).to.be.revertedWith("Cannot swap 0 tokens");
  });

  it("should not allow removing more liquidity than exists", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const amountX = 100;
    const amountY = 200;

    await TestTokenX.transfer(alice.address, amountX);
    await TestTokenY.transfer(alice.address, amountY);

    await TestTokenX.connect(alice).approve(AMM.address, amountX);
    await TestTokenY.connect(alice).approve(AMM.address, amountY);

    await AMM.connect(alice).addLiquidity(amountX, amountY);

    await expect(AMM.removeLiquidity(2)).to.be.revertedWith("Insufficient liquidity");
  });

  it("should not allow swapping tokens if balance is insufficient", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const amountIn = 100;

    await TestTokenX.transfer(alice.address, amountIn);

    await TestTokenX.connect(alice).approve(AMM.address, amountIn);

    await expect(AMM.swapTokens(amountIn, 0)).to.be.revertedWith("Insufficient balance");
  });

  it("should not allow swapping tokens if slippage is too high", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const amountIn = 100;
    const reserveX = 1000;
    const reserveY = 2000;

    await TestTokenX.transfer(alice.address, amountIn);

    await TestTokenX.connect(alice).approve(AMM.address, amountIn);

    await expect(AMM.swapTokens(amountIn, await AMM.calculateExpected(amountIn, reserveX, reserveY) + 1)).to.be.revertedWith("Slippage too high");
  });

  it("should calculate expected swap amount correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMaker;
    const reserveX = 1000;
    const reserveY = 2000;

    expect(await AMM.calculateExpected(100, reserveX, reserveY)).to.equal(200);
  });
});

  /* it("should add liquidity correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMakerV2;
    const amountX = 100;
    const amountY = 200;
    const liquidity = Math.sqrt(amountX * amountY);

    await TestTokenX.transfer(alice.address, amountX);
    await TestTokenY.transfer(alice.address, amountY);

    await TestTokenX.connect(alice).approve(AMM.address, amountX);
    await TestTokenY.connect(alice).approve(AMM.address, amountY);

    await AMM.connect(alice).addLiquidity(amountX, amountY);

    expect(await TestTokenX.balanceOf(AMM.address)).to.equal(amountX);
    expect(await TestTokenY.balanceOf(AMM.address)).to.equal(amountY);
    expect(await AMM.balanceOf(alice.address)).to.equal(liquidity);
    expect(await AMM.totalSupply()).to.equal(liquidity);
  });

  it("should remove liquidity correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMakerV2;
    const amountX = 100;
    const amountY = 200;
    const liquidity = Math.sqrt(amountX * amountY);

    await TestTokenX.transfer(alice.address, amountX);
    await TestTokenY.transfer(alice.address, amountY);

    await TestTokenX.connect(alice).approve(AMM.address, amountX);
    await TestTokenY.connect(alice).approve(AMM.address, amountY);

    await AMM.connect(alice).addLiquidity(amountX, amountY);

    await AMM.connect(alice).removeLiquidity(liquidity);

    expect(await TestTokenX.balanceOf(AMM.address)).to.equal(0);
    expect(await TestTokenY.balanceOf(AMM.address)).to.equal(0);
    expect(await AMM.balanceOf(alice.address)).to.equal(0);
    expect(await AMM.totalSupply()).to.equal(0);
  });

  it("should swap tokens correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMakerV2;
    const amountX = 100;
    const amountY = 200;
    const amountIn = 10;
    const fee = amountIn * FEE_PERCENT / FEE_MAX;    await TestTokenX.transfer(alice.address, amountIn);

    await TestTokenX.connect(alice).approve(AMM.address, amountIn);

    const expectedOut = calculateExpected(amountIn, amountX, amountY);

    await AMM.connect(alice).swapTokens(amountIn, expectedOut);

    expect(await TestTokenX.balanceOf(alice.address)).to.equal(0);
    expect(await TestTokenY.balanceOf(alice.address)).to.equal(expectedOut);
    expect(await TestTokenX.balanceOf(AMM.address)).to.equal(amountX + amountIn - fee);
    expect(await TestTokenY.balanceOf(AMM.address)).to.equal(amountY - expectedOut);
    expect(await AMM.balanceOf(alice.address)).to.equal(0);
    expect(await AMM.totalSupply()).to.equal(0);
  });

  it("should emit events correctly", async function () {
    const AMM = ConstantProductAutomatedMarketMakerV2;
    const amountX = 100;
    const amountY = 200;
    const amountIn = 10;
    const fee = amountIn * FEE_PERCENT / FEE_MAX;

    await TestTokenX.transfer(alice.address, amountIn);

    await TestTokenX.connect(alice).approve(AMM.address, amountIn);

    const expectedOut = calculateExpected(amountIn, amountX, amountY);

    await expect(AMM.connect(alice).swapTokens(amountIn, expectedOut))
      .to.emit(AMM, "Swapped")
      .withArgs(alice.address, TestTokenX.address, amountIn, TestTokenY.address, expectedOut);

    await expect(AMM.connect(alice).addLiquidity(amountX, amountY))
      .to.emit(AMM, "AddedLiquidity")
      .withArgs(alice.address, TestTokenX.address, amountX, TestTokenY.address, amountY, Math.sqrt(amountX * amountY));

    await expect(AMM.connect(alice).removeLiquidity(Math.sqrt(amountX * amountY)))
      .to.emit(AMM, "RemovedLiquidity")
      .withArgs(alice.address, TestTokenX.address, amountX, TestTokenY.address, amountY, Math.sqrt(amountX * amountY));
  }); */