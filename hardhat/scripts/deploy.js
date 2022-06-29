const { expect } = require("chai");
const { Wallet } = require("ethers");
const { ethers } = require("hardhat");
const fs = require('fs');


let bingoGameFactoryContract;
let bingoGameContract;
let bingoBoardNFTContract;
let bingoGameSBTContract;

async function incrementBlockChainTime(timeStampIncrement) {
  const currentBlockNumber = await ethers.provider.getBlockNumber();
  const currentTimeStamp = (await ethers.provider.getBlock(currentBlockNumber)).timestamp;
  const increasedTimeStamp = currentTimeStamp + timeStampIncrement;
  await ethers.provider.send("evm_mine", [increasedTimeStamp]);
}

 async function main() {
    let signers = await ethers.getSigners();
    const bingoGameSBT = await ethers.getContractFactory("BingoSBT");
    const bingoBoardNFT = await ethers.getContractFactory("BingoBoardNFT");
    const bingoGame = await ethers.getContractFactory("BingoGame");
    const bingoGameFactory = await ethers.getContractFactory("BingoGameFactory");

    // Deploy NFT & SBT Contracts
    bingoBoardNFTContract = await bingoBoardNFT.deploy();
    await bingoBoardNFTContract.deployed();
    console.log("bingoBoardNFTContract: %s", bingoBoardNFTContract.address);
    bingoGameSBTContract = await bingoGameSBT.deploy();
    await bingoGameSBTContract.deployed();
    console.log("bingoGameSBTContract: %s", bingoGameSBTContract.address);

    // Deploy BingoGame Contract, transfer ownership of SBT
    bingoGameContract = await bingoGame.deploy(
      bingoBoardNFTContract.address,
      bingoGameSBTContract.address
    );
    await bingoGameContract.deployed();
    console.log("bingoGameContract: %s", bingoGameContract.address);
    // bingoGameSBTContract.transferOwnership(bingoGameContract.address);

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
    await bingoBoardNFTContract.transferOwnership(bingoGameFactoryContract.address);
    await bingoGameSBTContract.transferOwnership(bingoGameFactoryContract.address);

    const config = {
        bingoGameFactoryContract: bingoGameFactoryContract.address,
        bingoGameContract: bingoGameContract.address,
        bingoBoardNFTContract: bingoBoardNFTContract.address,
        bingoGameSBTContract: bingoGameSBTContract.address
      }
    
      fs.writeFileSync("../frontendjs/data/__config.json", JSON.stringify(config, null, 2));

      // TODO: Move this somewhere more appropriate. This is only for initializing contracts
      //       in order to test the front-end
      for(let i = 0; i < 10; ++i){
        await bingoGameFactoryContract.createGameProposal(ethers.utils.parseEther('0.01'), 15 + i, 2 + i, 1, {
          value: ethers.utils.parseUnits("0.01", "ether")
        });
      }

      await bingoGameFactoryContract.connect(signers[1]).joinGameProposal(0, 1, { value: ethers.utils.parseEther("0.01") });
      await bingoGameFactoryContract.connect(signers[11]).joinGameProposal(2, 2, { value: ethers.utils.parseEther("0.02") });

      await bingoGameFactoryContract.connect(signers[9]).joinGameProposal(1, 2, { value: ethers.utils.parseEther("0.02") });
      
      for(let i = 0; i < 55; i++) {
        await incrementBlockChainTime(15);
        await bingoGameContract
          .attach("0x3f3c0fa2f1998a358a882cd187a13990afde12f1")
          .drawNumber();
      }
    }


  main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });














