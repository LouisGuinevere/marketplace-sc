const Marketplace721 = artifacts.require('Marketplace721');

module.exports = async function(deployer) {
    await deployer.deploy(Marketplace721);
}