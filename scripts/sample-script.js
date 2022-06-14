const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const Bingo = await hre.ethers.getContractFactory("Bingo");
  const bingo = await Bingo.deploy();
  await bingo.deployed();
  console.log("Bingo deployed to: ", bingo.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
