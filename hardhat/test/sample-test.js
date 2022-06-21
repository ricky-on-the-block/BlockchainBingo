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

    it("createGameProposal() should FAIL with < weiBuyIn", async function () {
      await expect( bingoGameFactoryContract
        .connect(signers[0])
        .createGameProposal(0, 10, 5, 1, {
          value: ethers.utils.parseUnits("1", "wei"),
        })).to.be.revertedWith("MIN_WEI_BUY_IN not met");
    });

    it("createGameProposal() should FAIL with > drawTimeIntervalSec", async function () {
          await expect( bingoGameFactoryContract
            .connect(signers[0])
            .createGameProposal(1, 120, 5, 1, {
              value: ethers.utils.parseUnits("1", "wei"),
            })).to.be.revertedWith("drawTimeIntervalSec > MAX_DRAW_INTERVAL_SEC");
        });

    it("createGameProposal() should FAIL with < numPlayersRequired", async function () {
      await expect( bingoGameFactoryContract
        .connect(signers[0])
        .createGameProposal(1, 10, 2, 1, {
          value: ethers.utils.parseUnits("1", "wei"),
        })).to.be.revertedWith("MIN_NUM_PLAYERS not met");
    });

    it("createGameProposal() should FAIL with > numCardsDesired", async function () {
      await expect( bingoGameFactoryContract
        .connect(signers[0])
        .createGameProposal(1, 10, 5, 11, {
          value: ethers.utils.parseUnits("11", "wei"),
        })).to.be.revertedWith("May not request more than MAX_CARDS_PER_PLAYERS");
    });

    it("createGameProposal() should FAIL with < weiBuyIn * numCardsDesired", async function () {
      await expect( bingoGameFactoryContract
        .connect(signers[0])
        .createGameProposal(1, 10, 5, 8, {
          value: ethers.utils.parseUnits("6", "wei"),
        })).to.be.revertedWith("Value must be >= weiBuyIn * numCardsDesired");
    });

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
      ).to.be.revertedWith("Value must be >= weiBuyIn * numCardsDesired");
    });

    it("joinGameProposal() should FAIL with > numCardsDesired", async function () {
      await expect(
        bingoGameFactoryContract.connect(signers[1]).joinGameProposal(1, 20, {
          value: ethers.utils.parseUnits("20", "wei"),
        })
      ).to.be.revertedWith("May not request more than MAX_CARDS_PER_PLAYERS");
    });

    it("joinGameProposal() should SUCCEED with 2nd time sign-up", async function () {
      await bingoGameFactoryContract.connect(signers[0]).joinGameProposal(1, 1, {
          value: ethers.utils.parseUnits("1", "wei"),
        });
    });

    it("joinGameProposal() should FAIL with 2nd time signup && < payment amount", async function () {
      await expect(bingoGameFactoryContract.connect(signers[0]).joinGameProposal(1, 2, {
          value: ethers.utils.parseUnits("1", "wei")})).to.be.revertedWith("Value must be >= weiBuyIn * numCardsDesired");
    });

    it("joinGameProposal() should FAIL with 2nd time signup && > numCardsDesire", async function () {
      await expect(bingoGameFactoryContract.connect(signers[0]).joinGameProposal(1, 9, {
          value: ethers.utils.parseUnits("9", "wei")})).to.be.revertedWith("May not request more than MAX_CARDS_PER_PLAYERS");
    });
    
    it("joinGameProposal() should SUCCEED with valid input", async function () {
      await bingoGameFactoryContract
        .connect(signers[1])
        .joinGameProposal(1, 2, { value: ethers.utils.parseUnits("2", "wei") });
    });

    it("joinGameProposal() should SUCCED to create game with enough players", async function () {
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

    it("joinGameProposal() should FAIL with gameProposal != active", async function () {
      await expect(
        bingoGameFactoryContract.connect(signers[5]).joinGameProposal(1, 2, {
          value: ethers.utils.parseUnits("2", "wei"),
        })
      ).to.be.revertedWith("Must select an active gameProposal");
    });
  });

  describe("BingoGame Tests", function () {
    // Test win conditions
    // 1. claimBingo fails with no drawnNumbers
    it("claimBingo() should FAIL with invalid tokenID", async function () {
      await expect(
        bingoGameContract
          .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
          .connect(signers[0])
          .claimBingo(9999999)
      ).to.be.reverted;
    });

    it("claimBingo() should FAIL with owner_tokenID != msg.sender", async function () {
      await expect(
        bingoGameContract
          .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
          .connect(signers[0])
          .claimBingo(2)
      ).to.be.revertedWith("Only the board owner can use this tokenId");
    });

    it("getWinnings() should FAIL with msg.sender != winner", async function() {
      expect(bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .getWinnings()).to.be.revertedWith("Only winners can getWinnings()");
   });

    it("claimBingo() should SUCCED with 75 drawnNumbers", async function () {
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

    it("claimBingo() should FAIL with hasBoardWon[tokenId] (already claim bingo)", async function () {
      expect(bingoGameContract
        .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
        .connect(signers[0])
        .claimBingo(0)).to.be.revertedWith("Cannot claim bingo for multiple board");
    });

    it("getWinnings() should SUCCED with isBingo=true", async function() {
      await expect(
        await bingoGameContract
        .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
        .connect(signers[0])
        .getWinnings()).to.changeEtherBalance(signers[0], +10)
  });

    it("getWinnings() should FAIL with hasWinnerBeenPaid=true", async function() {
      await expect(
       bingoGameContract
       .attach("0xfbd7b064bc43c7bcfe35239c587cc3604c88f299")
       .connect(signers[0])
       .getWinnings()
      ).to.be.revertedWith("Winner can not be paid twice");
  });
  });

  // Test Multiple Winners
  describe("BingoGame Multiple Winners", function () {

    // claimBingo allows multiple winners with 75 drawnNumbers
    it("createGameProposal() should SUCCED to create 2nd game with sign-ups", async function () {
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

    });

    it("claimBingo() should FAIL with tokenID not part of gameUUID", async function() {
      expect(bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .claimBingo(0)).to.be.revertedWith("Can only claim Bingo on this games cards");
   });

   it("getWinnings() should FAIL with owner!=winner", async function() {
    expect(bingoGameContract
      .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
      .connect(signers[0])
      .getWinnings()).to.be.revertedWith("Only winners can getWinnings()");
 });

    it("claimBingo() should SUCCED with multiple winners && 75 drawnNumbers", async function() {
      for (i = 0; i < 75; i++) {
        await bingoGameContract
          .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
          .connect(signers[0])
          .drawNumber();
      }
      await bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .claimBingo(10);
      await bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[1])
        .claimBingo(11);
   });

    it("getWinnings() should SUCCED with multiple winners (distribute winnings equal to share)", async function() {
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

    it("getWinnings() should FAIL with hasWinnerBeenPaid=true", async function() {
       await expect(
        bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[0])
        .getWinnings()
       ).to.be.revertedWith("Winner can not be paid twice");

       await expect(
        bingoGameContract
        .attach("0x2006d0fcbfd3334755b501823fa4e234d8eb3969")
        .connect(signers[1])
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
