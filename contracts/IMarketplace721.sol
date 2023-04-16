// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IMarketplace721 {
    struct ListedNFT {
        address nftContractAddress;
        uint256 tokenId;
        address owner;
        uint256 price;
        bool status;
    }

    event ListingNFT(
        address owner,
        address nftContracAddress,
        uint256 tokenId,
        uint256 price,
        string name,
        string description,
        string imageURL,
        uint256 time
    );

    event BuyingNFT(
        address buyer,
        address seller,
        address nftContractAddress,
        uint256 tokenId,
        uint256 price,
        uint256 time
    );

    event UnlistNFT(
        address owner,
        address nftContractAddress,
        uint256 tokenId,
        uint256 time
    );
}
