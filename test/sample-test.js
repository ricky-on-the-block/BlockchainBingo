const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BingoGame Unit Tests", function () {
  let bg;
  before(async function () {
    const BingoGame = await ethers.getContractFactory("BingoGame");
    bg = await BingoGame.deploy();
    await bg.deployed();
  });

  it("joinGame() should SUCCEED with valid input", async function () {
    let signer = (await ethers.getSigners())[0];
    await bg.connect(signer).joinGame({ value: ethers.utils.parseUnits('10', 'wei')});
  });

  it("joinGame() should FAIL with < WEI_BUY_IN", async function () {
    let signer = (await ethers.getSigners())[1];
    await expect(
      bg.connect(signer).joinGame({ value: ethers.utils.parseUnits('9', 'wei')})).to.be.reverted;
  });

  it("joinGame() should FAIL on duplicate calls from the same address", async function () {
    let signer = (await ethers.getSigners())[2];
    await bg.connect(signer).joinGame({ value: ethers.utils.parseUnits('10', 'wei')});
    await expect(bg.connect(signer).joinGame({ value: ethers.utils.parseUnits('10', 'wei')})).to.be.reverted;
  });

  it("getBoard() should return a valid string", async function () {
    let signer = (await ethers.getSigners())[2];
    await bg.connect(signer).getBoard();
  });

  it("drawNumber() should succeed", async function() {
    let owner = (await ethers.getSigners())[0];
    await bg.connect(owner).startGame();
    await bg.connect(owner).drawNumber();
    // console.log(await bg.drawnNumbers());
  });
});
