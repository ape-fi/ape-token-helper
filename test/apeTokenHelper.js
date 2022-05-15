const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('ApeTokenHelper', async () => {
  const toWei = ethers.utils.parseEther;
  const exchangeRate = toWei('100');

  let accounts;
  let admin, adminAddress;
  let user1, user1Address;

  let comptroller;
  let token1, token2;
  let apeToken1, apeToken2;
  let helper;

  beforeEach(async () => {
    accounts = await ethers.getSigners();
    admin = accounts[0];
    adminAddress = await admin.getAddress();
    user1 = accounts[1];
    user1Address = await user1.getAddress();

    const comptrollerFactory = await ethers.getContractFactory('MockComptroller');
    comptroller = await comptrollerFactory.deploy();

    const tokenFactory = await ethers.getContractFactory('MockToken');
    token1 = await tokenFactory.deploy();
    token2 = await tokenFactory.deploy();

    const apeTokenFactory = await ethers.getContractFactory('MockApeToken');
    apeToken1 = await apeTokenFactory.deploy(token1.address);
    apeToken2 = await apeTokenFactory.deploy(token2.address);

    await Promise.all([
      apeToken1.setExchangeRateStored(exchangeRate),
      apeToken2.setExchangeRateStored(exchangeRate),
      comptroller.supportMarket(apeToken1.address)
    ]);

    const helperFactory = await ethers.getContractFactory('ApeTokenHelper');
    helper = await helperFactory.deploy(comptroller.address);
  });

  describe('mint', async () => {
    const mintAmount = toWei('1');

    it('mints successfully', async () => {
      await token1.approve(helper.address, mintAmount);
      await helper.mint(apeToken1.address, mintAmount);

      expect(await apeToken1.balanceOf(adminAddress)).to.eq(toWei('100'));
      expect(await token1.balanceOf(apeToken1.address)).to.eq(toWei('1'));
    });

    it('fails to mint for market not list', async () => {
      await token2.approve(helper.address, mintAmount);
      await expect(helper.mint(apeToken2.address, mintAmount)).to.be.revertedWith('market not list');
    });
  });

  describe('mint and borrow', async () => {
    const mintAmount = toWei('1');
    const borrowAmount = toWei('1');

    beforeEach(async () => {
      await Promise.all([
        token2.transfer(apeToken2.address, toWei('100')),
        comptroller.supportMarket(apeToken2.address)
      ]);
    });

    it('mints and borrows successfully', async () => {
      await token1.approve(helper.address, mintAmount);
      await helper.mintBorrow(apeToken1.address, mintAmount, apeToken2.address, borrowAmount);

      expect(await apeToken1.balanceOf(adminAddress)).to.eq(toWei('100'));
      expect(await token1.balanceOf(apeToken1.address)).to.eq(toWei('1'));
      expect(await token2.balanceOf(adminAddress)).to.eq(toWei('9901')); // 10000 (initital) - 100 (faucet to apeToken) + 1 (borrow)
    });
  });

  describe('repay', async () => {
    const mintAmount = toWei('1');
    const borrowAmount = toWei('1');

    beforeEach(async () => {
      await Promise.all([
        token2.transfer(apeToken2.address, toWei('100')),
        comptroller.supportMarket(apeToken2.address)
      ]);
      await token1.approve(helper.address, mintAmount);
      await helper.mintBorrow(apeToken1.address, mintAmount, apeToken2.address, borrowAmount);
    });

    it('repays successfully', async () => {
      expect(await token2.balanceOf(apeToken2.address)).to.eq(toWei('99'));

      await token2.approve(helper.address, borrowAmount);
      await helper.repay(apeToken2.address, borrowAmount);

      expect(await token2.balanceOf(apeToken2.address)).to.eq(toWei('100'));
    });
  });

  describe('repay and redeem', async () => {
    const mintAmount = toWei('1');
    const borrowAmount = toWei('1');

    beforeEach(async () => {
      await Promise.all([
        token2.transfer(apeToken2.address, toWei('100')),
        comptroller.supportMarket(apeToken2.address)
      ]);
      await token1.approve(helper.address, mintAmount);
      await helper.mintBorrow(apeToken1.address, mintAmount, apeToken2.address, borrowAmount);
    });

    it('repays and redeems successfully', async () => {
      expect(await token2.balanceOf(apeToken2.address)).to.eq(toWei('99'));

      await token2.approve(helper.address, borrowAmount);
      await helper.repayRedeem(apeToken2.address, borrowAmount, apeToken1.address, 0, mintAmount);

      expect(await token2.balanceOf(apeToken2.address)).to.eq(toWei('100'));
      expect(await token1.balanceOf(adminAddress)).to.eq(toWei('10000'));
    });
  });
});
