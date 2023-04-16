// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IMarketplace1155.sol";

contract Marketplace1155 is Ownable, IMarketplace1155 {
    uint256 private _listingFee = 1 ether;
    Counters.Counter listCounter;
    address private _marketOwner;

    //mapping from nft contract address to sellId to sellingInfo
    mapping(uint256 => ListedNFT) listedNftsList;

    constructor() {
        _marketOwner = msg.sender;
    }

    function _verifyCollection(
        address walletAddress,
        address nftContractAddress,
        uint256 tokenId,
        bytes memory signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encode(walletAddress, nftContractAddress, tokenId)
                ),
                signature
            );
    }

    function getListedNFT(
        address nftContractAddress,
        uint256 sellId
    )
        external
        view
        returns (address, address, uint256, uint256, uint256, bool)
    {
        ListedNFT memory nft = listedNftsList[sellId];
        return (
            nftContractAddress,
            nft.owner,
            nft.tokenId,
            nft.amount,
            nft.price,
            nft.status
        );
    }

    function getListingFee() external view returns (uint256) {
        return _listingFee;
    }

    function setListingFee(uint256 newFee) external onlyOwner {
        _listingFee = newFee;
    }

    function withdrawBalance() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function listNFT(
        address nftContractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        string memory name,
        string memory description,
        string memory imageURL,
        bytes memory signature
    ) external payable {
        require(
            msg.value >= _listingFee,
            "Marketplace: You have to pay us some fee for listing nft"
        );
        require(
            _verifyCollection(
                msg.sender,
                nftContractAddress,
                tokenId,
                signature
            ) == _marketOwner,
            "Marketplace: You are listing nfts belongs to an unregistered collection"
        );
        require(
            IERC1155(nftContractAddress).balanceOf(msg.sender, tokenId) >=
                amount,
            "Marketplace: You cant list that much nfts for sale"
        );
        require(price > 0, "Marketplace: You cannot sell these nfts for free");

        uint256 listId = Counters.current(listCounter);

        listedNftsList[listId] = ListedNFT(
            listId,
            msg.sender,
            nftContractAddress,
            tokenId,
            amount,
            price,
            true
        );

        Counters.increment(listCounter);

        emit ListingNFT(
            listId,
            msg.sender,
            nftContractAddress,
            tokenId,
            amount,
            price,
            name,
            description,
            imageURL,
            block.timestamp
        );
    }

    function unlistNFT(uint256 listId) external {
        ListedNFT memory listedNft = listedNftsList[listId];

        require(
            listedNft.status == true,
            "Marketplace: You cannot unlist an unlisted batch of nfts"
        );
        require(
            msg.sender == listedNft.owner,
            "Marketplace: You cannot unlist this batch of nfts"
        );

        delete listedNftsList[listId];

        emit UnlistNFT(
            listId,
            msg.sender,
            listedNft.nftContractAddress,
            listedNft.tokenId,
            listedNft.amount,
            block.timestamp
        );
    }

    function buyNFT(uint256 listId) external payable {
        ListedNFT memory listedNft = listedNftsList[listId];

        require(
            listedNft.status == true,
            "Marketplace: You cannot buy an unlisted batch of nfts"
        );
        require(
            msg.value >= listedNft.price,
            "Marketplace1155: Not enough money to cover rental period"
        );

        payable(listedNft.owner).transfer(listedNft.price * 1e18);

        IERC1155(listedNft.nftContractAddress).safeTransferFrom(
            listedNft.owner,
            msg.sender,
            listedNft.tokenId,
            listedNft.amount,
            ""
        );
        delete listedNftsList[listId];

        emit BuyingNFT(
            msg.sender,
            listedNft.owner,
            listId,
            listedNft.nftContractAddress,
            listedNft.tokenId,
            listedNft.amount,
            listedNft.price,
            block.timestamp
        );
    }
}
