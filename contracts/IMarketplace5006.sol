// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IMarketplace5006 {
    struct Leasing {
        bytes32 leaseId;
        address owner;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 availableFrom;
        uint256 availableTo;
    }

    struct Renting {
        bytes32 leaseId;
        address user;
        address nftContract;
        uint256 startDate;
        uint256 endDate;
        uint256 rentalFee;
    }

    event LeasingNFT(
        bytes32 leaseId,
        address owner,
        address originalNftContract,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 availableFrom,
        uint256 availableTo,
        string name,
        string description,
        string imageURL
    );

    event RentingNFT(
        bytes32 leaseId,
        uint8 rentId,
        address owner,
        address user,
        address originalNftContract,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 rentalFee,
        uint256 time
    );

    event UnleaseNFT(address nftContract, bytes32 leaseId);

    function isRentableNFT(address nftContract) external view returns (bool);

    function getLeasingTime(
        address nftContract,
        bytes32 leaseId
    ) external view returns (uint256, uint256);
}
