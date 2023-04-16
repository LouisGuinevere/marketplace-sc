const Marketplace1155 = artifacts.require('Marketplace1155');

module.exports = async function(deployer) {
    await deployer.deploy(Marketplace1155);
}