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

  // it("Should return the new greeting once it's changed", async function () {
  //   expect(await bingo.greet()).to.equal("Hello, world!");

  //   const setGreetingTx = await bingo.setGreeting("Hola, mundo!");

  //   // wait until the transaction is mined
  //   await setGreetingTx.wait();

  //   expect(await bingo.greet()).to.equal("Hola, mundo!");
  // });
});
