const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
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
  bingoBoardNFTContract.transferOwnership(bingoGameFactoryContract.address);
  bingoGameSBTContract.transferOwnership(bingoGameFactoryContract.address);

  const minWeiBuyIn = await bingoGameFactoryContract.MIN_WEI_BUY_IN();
  const minEthBuyIn = ethers.utils.formatEther(minWeiBuyIn);
  console.log(minEthBuyIn);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
