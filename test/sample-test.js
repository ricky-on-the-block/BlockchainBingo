const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Bingo Unit Tests", function () {
  let bingo;
  before(async function () {
    const Bingo = await ethers.getContractFactory("Bingo");
    bingo = await Bingo.deploy();
    await bingo.deployed();
  });

  it("joinGame() should SUCCEED with valid input", async function () {
    let signer = (await ethers.getSigners())[0];
    await bingo.connect(signer).joinGame({ value: ethers.utils.parseUnits('10', 'wei')});
  });

  it("joinGame() should FAIL with < WEI_BUY_IN", async function () {
    let signer = (await ethers.getSigners())[1];
    await expect(
      bingo.connect(signer).joinGame({ value: ethers.utils.parseUnits('9', 'wei')})).to.be.reverted;
  });

  it("joinGame() should FAIL on duplicate calls from the same address", async function () {
    let signer = (await ethers.getSigners())[2];
    await bingo.connect(signer).joinGame({ value: ethers.utils.parseUnits('10', 'wei')});
    await expect(bingo.connect(signer).joinGame({ value: ethers.utils.parseUnits('10', 'wei')})).to.be.reverted;
  });

  it("getBoard() should return a valid string", async function () {
    let signer = (await ethers.getSigners())[2];
    await bingo.connect(signer).getBoard();
  });

  it("drawNumber() should succeed", async function() {
    let owner = (await ethers.getSigners())[0];
    await bingo.connect(owner).startGame();
    await bingo.connect(owner).drawNumber();
    // console.log(await bingo.drawnNumbers());
  });
});
