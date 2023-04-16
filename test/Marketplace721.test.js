const chai = require("chai");
const { solidity } = require("ethereum-waffle");
const expect = chai.expect;
chai.use(solidity);
const Web3 = require('web3');
const EthCrypto = require('eth-crypto');
require("dotenv").config();

const web3 = new Web3(Web3.givenProvider || "ws://localhost:7545");
const ERC20 = artifacts.require("ERC20Sample");
const ERC721 = artifacts.require("ERC721Sample");
const Marketplace721 = artifacts.require("Marketplace721");
const PRIVATE_KEY = "90acc9ed225d4ede5679f8485d5120142a6439bf1f00d7789e4c19347da777c4"

function verifyCollection(walletAddress, nftContract, tokenId) {
    const hash = web3.utils.keccak256(
        web3.eth.abi.encodeParameters(
          ['address', 'address', 'uint256'],
          [walletAddress, nftContract, tokenId],
        ),
    );
    const signature = EthCrypto.sign(PRIVATE_KEY, hash);
    return signature;
}

contract("Marketplace", (accounts) => {

    const tokenId = 0;
    const invalidTokenId = 1;
    const initBalance = BigInt("100000");
    const listUser = accounts[0];
    const buyUser = accounts[1];
    const invalidListUser = accounts[2];
    const listingFee = web3.utils.toWei('1', "ether");
    const invalidListingFee = web3.utils.toWei('0.2', "ether");
    let erc20, erc721, marketplace;

    before(async () => {
        erc20 = await ERC20.deployed();
        erc721 = await ERC721.deployed();
        marketplace = await Marketplace721.deployed();
        await erc20.mint(listUser, initBalance);
        await erc20.mint(buyUser, initBalance);
    })

    // List NFT

    it('Revert if the list user doesnt pay enough listing fee', async () => {
        
        const signature = verifyCollection(listUser, erc721.address, tokenId);

        await expect(marketplace.listNFT(
            erc721.address,
            tokenId,
            erc20.address,
            20,
            signature,
            {
                from: listUser,
                value: invalidListingFee
            }
        )).to.be.revertedWith("Marketplace: You have to pay us some ether for listing nft");
    })

    it('Revert if the list user is not the owner of the nft', async () => {
        const signature = verifyCollection(invalidListUser, erc721.address, tokenId);

        await expect(marketplace.listNFT(
            erc721.address,
            tokenId,
            erc20.address,
            20,
            signature,
            {
                from: invalidListUser,
                value: listingFee
            }
        )).to.be.revertedWith("Marketplace: You dont have permission to list this nft for sale");
    })

    it('Revert if the list user is listing a nft for free', async () => {
        const signature = verifyCollection(listUser, erc721.address, tokenId);

        await expect(marketplace.listNFT(
            erc721.address,
            tokenId,
            erc20.address,
            0,
            signature,
            {
                from: listUser,
                value: listingFee
            }
        )).to.be.revertedWith("Marketplace: You cannot sell this nft for free");
    })

    it('List nft successfully', async () => {
        const signature = verifyCollection(listUser, erc721.address, tokenId);

        await marketplace.listNFT(
            erc721.address, 
            tokenId, 
            erc20.address, 
            20,
            signature,
            {
                from: listUser,
                value: listingFee,
            }
        )

        const contractBalance = await web3.eth.getBalance(marketplace.address);
        expect(contractBalance).to.be.equal(listingFee);
    })



    it('Revert if the list user is listing a listed nft', async () => {
        const signature = verifyCollection(listUser, erc721.address, tokenId);

        await expect(marketplace.listNFT(
            erc721.address, 
            tokenId, 
            erc20.address, 
            20,
            signature,
            {
                from: listUser,
                value: listingFee,
            }
        )).to.be.revertedWith("Marketplace: You cannot list a listed nft");
    })

    // Buy NFT

    it('Revert if the buying nft is not listed', async () => {
        await expect(marketplace.buyNFT(
            erc721.address,
            invalidTokenId,
            {
                from: buyUser,
            }
        )).to.be.revertedWith("Marketplace: You cannot buy an unlisted/disabled nft");
    })

    it('Revert if the buyer is the seller', async () => {
        await expect(marketplace.buyNFT(
            erc721.address,
            tokenId,
            {
                from: listUser,
            }
        )).to.be.revertedWith("Marketplace: You cannot buy your own nft");
    })

    it('Buy successfully', async () => {

        await erc20.approve(marketplace.address, 20, {from: buyUser});
        await erc721.approve(marketplace.address, tokenId, {from: listUser});

        await marketplace.buyNFT(
            erc721.address,
            tokenId,
            {
                from: buyUser,
            }
        )
        expect((await erc721.ownerOf(tokenId))).to.be.equal(buyUser);
    })
})