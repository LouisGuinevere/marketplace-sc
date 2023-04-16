// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IMarketplace1155 {
    struct ListedNFT {
        uint256 listId;
        address owner;
        address nftContractAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        bool status;
    }

    event ListingNFT(
        uint256 listId,
        address owner,
        address nftContracAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        string name,
        string description,
        string imageURL,
        uint256 time
    );

    event BuyingNFT(
        address buyer,
        address seller,
        uint256 listId,
        address nftContractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 time
    );

    event UnlistNFT(
        uint256 listId,
        address owner,
        address nftContractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 time
    );
}
