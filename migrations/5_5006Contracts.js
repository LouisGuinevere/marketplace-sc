const ERC5006Sample = artifacts.require("ERC5006Sample");
const ERC1155Sample = artifacts.require("ERC1155Sample");
const Marketplace5006 = artifacts.require("Marketplace5006");

module.exports = async function (deployer) {
  await deployer.deploy(ERC1155Sample);
  await deployer.deploy(Marketplace5006);
  await deployer.deploy(
    ERC5006Sample,
    Marketplace5006.address,
    ERC1155Sample.address
  );
};
