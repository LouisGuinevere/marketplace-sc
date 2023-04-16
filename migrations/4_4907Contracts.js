const ERC4907Sample = artifacts.require("ERC4907Sample");
const ERC721Sample = artifacts.require("ERC721Sample");
const Marketplace4907 = artifacts.require("Marketplace4907");

module.exports = async function (deployer) {
  await deployer.deploy(ERC721Sample);
  await deployer.deploy(Marketplace4907);
  await deployer.deploy(
    ERC4907Sample,
    Marketplace4907.address,
    ERC721Sample.address,
    "League of Legends Token",
    "LLT"
  );
};
