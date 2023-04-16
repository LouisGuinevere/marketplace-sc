// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IMarketplace4907 {
    struct Leasing {
        bytes32 leaseId;
        address owner;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        uint256 availableFrom;
        uint256 availableTo;
    }

    struct Renting {
        bytes32 leaseId;
        address user;
        address nftContract;
        uint256 tokenId;
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
        uint256 startDate,
        uint256 endDate,
        uint256 rentalFee,
        uint256 time
    );

    event UnleaseNFT(address nftContract, uint256 tokenId);

    /// @notice function to lease NFT for rental
    /// @param nftContract  Contract address of NFT
    /// @param tokenId  ID of Token
    /// @param availableFrom  When the nft can start being rented
    /// @param availableTo  When the nft can no longer be rented
    /// @param signature  Signature verify nft
    function leaseNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 availableFrom,
        uint256 availableTo,
        string memory name,
        string memory description,
        string memory imageURL,
        bytes memory signature
    ) external payable;

    function unleaseNFT(address nftContract, uint256 tokenId) external;

    /// @notice function to rent an NFT
    /// @param nftContract  Contract address of NFT
    /// @param tokenId  ID of Token
    /// @param startDate   timestamp, The new user could star use the NFT
    /// @param endDate   timestamp, The new user could use the NFT before expires
    function rentNFT(
        address nftContract,
        uint256 tokenId,
        uint256 startDate,
        uint256 endDate
    ) external payable;

    /// @notice function to check if the NFT contract is of the rentable type
    /// @param nftContract  Contract address of NFT
    function isRentableNFT(address nftContract) external view returns (bool);

    /*
     * function to get all leasings
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function getAllLeasings() external view returns (Leasing[] memory);

    /// @notice function to get time leasing of rental NFT
    /// @param nftContract  Contract address of NFT
    /// @param tokenId  ID of Token
    function getLeasingTime(
        address nftContract,
        uint256 tokenId
    ) external view returns (uint256, uint256);

    /// @notice function to get leasing fee
    function getLeasingFee() external view returns (uint256);
}
