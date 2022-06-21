const { expect } = require("chai");
const { Wallet } = require("ethers");
const { ethers } = require("hardhat");

describe("All BingoGame Unit Tests", function () {
  let bingoGameFactoryContract;
  let bingoGameContract;
  let bingoBoardNFTContract;
  let signers;
  before(async function () {
    signers = await ethers.getSigners();

    const bingoGameSBT = await ethers.getContractFactory("BingoSBT");
    const bingoBoardNFT = await ethers.getContractFactory("BingoBoardNFT");
    const bingoGame = await ethers.getContractFactory("BingoGame");
    const bingoGameFactory = await ethers.getContractFactory(
      "BingoGameFactory"
    );

    // Deploy NFT & SBT Contracts
    bingoBoardNFTContract = await bingoBoardNFT.deploy();
    await bingoBoardNFTContract.deployed();
    console.log("bingoBoardNFTContract: %s", bingoBoardNFTContract.address);
    const bingoGameSBTContract = await bingoGameSBT.deploy();
    await bingoGameSBTContract.deployed();
    console.log("bingoGameSBTContract: %s", bingoGameSBTContract.address);

    // Deploy BingoGame Contract, transfer ownership of SBT
    bingoGameContract = await bingoGame.deploy(
      bingoBoardNFTContract.address,
      bingoGameSBTContract.address
    );
    await bingoGameContract.deployed();
    console.log("bingoGameContract: %s", bingoGameContract.address);
    bingoGameSBTContract.transferOwnership(bingoGameContract.address);

    // Deploy BingoGameFactory Contract, transfer ownership of NFT & BingoGame
    bingoGameFactoryContract = await bingoGameFactory.deploy(
      bingoGameContract.address,
      bingoBoardNFTContract.address,
      bingoGameSBTContract.address
    );
    await bingoGameFactoryContract.deployed();
    console.log(
      "bingoGameFactoryContract: %s",
      bingoGameFactoryContract.address
    );
    bingoBoardNFTContract.transferOwnership(bingoGameFactoryContract.address);
  });

  describe("BingoGameFactory Tests", function () {
    it("createGameProposal() should SUCCEED with valid input", async function () {
      await bingoGameFactoryContract
        .connect(signers[0])
        .createGameProposal(1, 10, 5, 1, {
          value: ethers.utils.parseUnits("1", "wei"),
        });
    });

    it("joinGameProposal() should FAIL with < payment amount", async function () {
      await expect(
        bingoGameFactoryContract.connect(signers[1]).joinGameProposal(1, 2, {
          value: ethers.utils.parseUnits("1", "wei"),
        })
      ).to.be.reverted;
    });

    it("joinGameProposal() should SUCCEED with valid input", async function () {
      await bingoGameFactoryContract
        .connect(signers[1])
        .joinGameProposal(1, 2, { value: ethers.utils.parseUnits("2", "wei") });
    });

    it("joinGameProposal() should create game with enough players", async function () {
      await bingoGameFactoryContract
        .connect(signers[2])
        .joinGameProposal(1, 2, { value: ethers.utils.parseUnits("2", "wei") });
      await bingoGameFactoryContract
        .connect(signers[3])
        .joinGameProposal(1, 2, { value: ethers.utils.parseUnits("2", "wei") });
      await bingoGameFactoryContract
        .connect(signers[4])
        .joinGameProposal(1, 2, { value: ethers.utils.parseUnits("2", "wei") });
    });

    it("joinGameProposal() should fail if game is already made", async function () {
      await expect(
        bingoGameFactoryContract.connect(signers[5]).joinGameProposal(1, 2, {
          value: ethers.utils.parseUnits("2", "wei"),
        })
      ).to.be.reverted;
    });
  });

  describe("BingoGame Tests", function () {
    // Test win conditions
    // 1. claimBingo fails with no drawnNumbers
    it("claimBingo() fails with invalid token ID", async function () {
      await expect(
        bingoGameContract
          .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
          .connect(signers[0])
          .claimBingo(9999999)
      ).to.be.reverted;
    });
    // 2. claimBingo succeeds with 75 drawnNumbers
    it("claimBingo() succeeds with 75 drawnNumbers", async function () {
      for (i = 0; i < 75; i++) {
        await bingoGameContract
          .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
          .connect(signers[0])
          .drawNumber();
      }
      await bingoGameContract
        .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
        .connect(signers[0])
        .claimBingo(0);
    });
  });

  // Test Multiple Winners
  describe("BingoGame Multiple Winners", function () {

    function timeout(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }

    // claimBingo allows multiple winners with 75 drawnNumbers
    it("claimBingo allows multiple winners with 75 drawnNumbers", async function () {
      await bingoGameFactoryContract
        .connect(signers[0])
        .createGameProposal(1, 10, 5, 1, {
          value: ethers.utils.parseUnits("1", "wei"),
        });

      await bingoGameFactoryContract
        .connect(signers[1])
        .joinGameProposal(2, 2, { value: ethers.utils.parseUnits("2", "wei") });

      await bingoGameFactoryContract
        .connect(signers[2])
        .joinGameProposal(2, 2, { value: ethers.utils.parseUnits("2", "wei") });

      await bingoGameFactoryContract
        .connect(signers[3])
        .joinGameProposal(2, 2, { value: ethers.utils.parseUnits("2", "wei") });

      await bingoGameFactoryContract
        .connect(signers[4])
        .joinGameProposal(2, 2, { value: ethers.utils.parseUnits("2", "wei") });

      for (i = 0; i < 75; i++) {
        await bingoGameContract
          .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
          .connect(signers[0])
          .drawNumber();
      }
      await bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .claimBingo(9);
      await bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[1])
        .claimBingo(10);
    });
    

    it("Winner should not receive the full jackpot", async function() {
       await expect(
        await bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .getWinnings()).to.changeEtherBalance(signers[0], +4)

        await expect(
          await bingoGameContract
          .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
          .connect(signers[1])
          .getWinnings()).to.changeEtherBalance(signers[1], +4)

    });

    it("Winner should not get paid twice", async function() {
       await expect(
        bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .getWinnings()
       ).to.be.revertedWith("Winner can not be paid twice");

       await expect(
        bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .getWinnings()
       ).to.be.revertedWith("Winner can not be paid twice");

   });

  });

  /*
  it("joinGame() should FAIL with < WEI_BUY_IN", async function () {
    let signer = (await ethers.getSigners())[1];
    await expect(
      bingoGameFactoryContract
        .connect(signer)
        .joinGame({ value: ethers.utils.parseUnits("9", "wei") })
    ).to.be.reverted;
  });

  it("joinGame() should FAIL on duplicate calls from the same address", async function () {
    let signer = (await ethers.getSigners())[2];
    await bingoGameFactoryContract
      .connect(signer)
      .joinGame({ value: ethers.utils.parseUnits("10", "wei") });
    await expect(
      bingoGameFactoryContract
        .connect(signer)
        .joinGame({ value: ethers.utils.parseUnits("10", "wei") })
    ).to.be.reverted;
  });

  it("getBoard() should return a valid string", async function () {
    let signer = (await ethers.getSigners())[2];
    await bingoGameFactoryContract.connect(signer).getBoard();
  });

  it("drawNumber() should succeed", async function () {
    let owner = (await ethers.getSigners())[0];
    await bingoGameFactoryContract.connect(owner).startGame();
    await bingoGameFactoryContract.connect(owner).drawNumber();
    // console.log(await bingoGameFactoryContract.drawnNumbers());
  });
  */
});
