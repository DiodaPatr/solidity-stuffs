const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Constant Sum Automatic Market Maker", function () {
    let deployer, testUser1, testUser2, testUser3;
    let amm, token1, token2, token3;
    const INITIAL_USER_BALANCE = 1000n * 10n ** 18n;
    const INITIAL_SUPPLY = 20000n * 10n ** 18n;
    before(async function() {

        // Set up users, deploy contracts
        [deployer, testUser1, testUser2, testUser3] = await ethers.getSigners();

        token1 = await (await ethers.getContractFactory("TestToken", deployer)).deploy("TestToken1", "TS1", INITIAL_SUPPLY);
        token2 = await (await ethers.getContractFactory("TestToken", deployer)).deploy("TestToken2", "TS2", INITIAL_SUPPLY);
        token3 = await (await ethers.getContractFactory("TestToken", deployer)).deploy("TestToken3", "TS3", INITIAL_SUPPLY);

        // Setup AMM with 1% fee
        amm = await (await ethers.getContractFactory("ConstantSumAMM", deployer)).deploy(token1.address, token2.address, 100);

        // Check if contracts are deployed properly
        expect(await ethers.provider.getCode(token1.address)).to.not.eq("0x");
        expect(await ethers.provider.getCode(token2.address)).to.not.eq("0x");
        expect(await ethers.provider.getCode(token3.address)).to.not.eq("0x");
        let token0Val = (await amm.viewToken0()).toString();
        let token1Val = (await amm.viewToken1()).toString();
        expect(token0Val).to.eq(token1.address.toString());
        expect(token1Val).to.eq(token2.address.toString());

        // Transfer some tokens to the test users
        await token1.transfer(testUser1.address, INITIAL_USER_BALANCE);
        await token1.transfer(testUser2.address, INITIAL_USER_BALANCE);
        await token2.transfer(testUser1.address, INITIAL_USER_BALANCE);
        await token2.transfer(testUser2.address, INITIAL_USER_BALANCE);
        await token3.transfer(testUser3.address, INITIAL_USER_BALANCE);

        expect((await token1.balanceOf(testUser1.address))).to.eq(INITIAL_USER_BALANCE);
        expect((await token2.balanceOf(testUser1.address))).to.eq(INITIAL_USER_BALANCE);
        expect((await token3.balanceOf(testUser1.address))).to.eq(0);

        await token1.connect(testUser1).approve(amm.address, INITIAL_SUPPLY);
        await token2.connect(testUser1).approve(amm.address, INITIAL_SUPPLY);
        await token3.connect(testUser1).approve(amm.address, INITIAL_SUPPLY);

        await token1.connect(testUser2).approve(amm.address, INITIAL_SUPPLY);
        await token2.connect(testUser2).approve(amm.address, INITIAL_SUPPLY);
        await token3.connect(testUser2).approve(amm.address, INITIAL_SUPPLY);

        await token1.connect(testUser3).approve(amm.address, INITIAL_SUPPLY);
        await token2.connect(testUser3).approve(amm.address, INITIAL_SUPPLY);
        await token3.connect(testUser3).approve(amm.address, INITIAL_SUPPLY);

    });

    it("Test adding liquidity", async function() {
        const ADDED_LIQ = 500n * 10n ** 18n;

        await amm.connect(testUser1).addLiquidity(ADDED_LIQ, ADDED_LIQ);

        expect(await token1.balanceOf(amm.address)).to.eq(ADDED_LIQ);
        expect(await token2.balanceOf(amm.address)).to.eq(ADDED_LIQ);

        await amm.connect(testUser2).addLiquidity(ADDED_LIQ, ADDED_LIQ);

        expect(await token1.balanceOf(amm.address)).to.eq(2n * ADDED_LIQ);
        expect(await token2.balanceOf(amm.address)).to.eq(2n * ADDED_LIQ);
    });

    it("Test Swap with existing token", async function() {
        const SWAP_AMOUNT = 100;
        const ADDED_LIQ = 100;
        const FEE = 1;

        await amm.connect(testUser1).addLiquidity(ADDED_LIQ, ADDED_LIQ);
        await amm.connect(testUser2).addLiquidity(ADDED_LIQ, ADDED_LIQ);

        await amm.connect(testUser1).swap(token1.address, SWAP_AMOUNT);

        expect(await token1.balanceOf(amm.address)).to.be.eq(ADDED_LIQ + SWAP_AMOUNT);
        expect(await token2.balanceOf(amm.address)).to.be.eq(ADDED_LIQ - SWAP_AMOUNT + FEE);

    });
    it("Test Swap with token not in the pool", async function() {
        const SWAP_AMOUNT = 200n * 10n ** 18n;

        await expect(amm.connect(testUser2).swap(token3.address, SWAP_AMOUNT)).to.be.reverted;

    });
    it("Test removing liquidity", async function() {
        const ADDED_LIQ = 500n * 10n ** 18n;

        await amm.connect(testUser1).removeLiquidity(500);
    });
});