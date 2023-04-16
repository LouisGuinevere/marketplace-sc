const ERC20Sample = artifacts.require('ERC20Sample');

module.exports = async function(deployer) {
    await deployer.deploy(ERC20Sample);
}
