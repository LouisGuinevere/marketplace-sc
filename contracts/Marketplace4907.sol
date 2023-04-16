// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMarketplace4907.sol";
import "./IERC4907.sol";
import "./ERC4907Sample.sol";

contract Marketplace4907 is ReentrancyGuard, IMarketplace4907, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address private _marketOwner;
    uint256 private _leasingFee = 1 ether;
    Counters.Counter private _nftsLeased;
    // maps contract address to token id to properties of the leasing
    mapping(address => mapping(uint256 => Leasing)) private _leasingMap;
    // maps contract address to token id to rentId to properties of the renting
    mapping(address => mapping(uint256 => mapping(uint8 => Renting))) _rentingMap;
    // maps contract address to token id to number of renting
    mapping(address => mapping(uint256 => uint8)) public _numberOfRentMap;
    // maps nft contracts to set of the tokens that are leased
    mapping(address => EnumerableSet.UintSet) private _nftContractTokensMap;
    // tracks the nft contracts that have been leased
    EnumerableSet.AddressSet private _nftContracts;

    constructor() {
        _marketOwner = msg.sender;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _verifySignature(
        address walletAddress,
        address nftContractAddress,
        uint256 tokenId,
        bytes memory _signature
    ) private pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encode(walletAddress, nftContractAddress, tokenId)
                ),
                _signature
            );
    }

    function withdrawBalance() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev See {IMarketplace-leaseNFT}.
     */
    function leaseNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 availableFrom,
        uint256 availableTo,
        string memory name,
        string memory description,
        string memory imageURL,
        bytes memory _signature
    ) public payable virtual override nonReentrant {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Marketplace4907: You are not the owner of nft"
        );
        require(msg.value >= _leasingFee, "Not enough ether for leasing fee");
        require(
            availableFrom >= block.timestamp,
            "Marketplace4907: Start date cannot be in the past"
        );
        require(
            availableTo > availableFrom,
            "Marketplace4907: End date cannot be before the start date"
        );
        Leasing storage leasing = _leasingMap[nftContract][tokenId];
        require(
            leasing.nftContract == address(0) ||
                block.timestamp > leasing.availableTo ||
                block.timestamp < leasing.availableFrom,
            "Marketplace4907: This NFT has already been leased in this time"
        );

        address signerOwner = _verifySignature(
            _marketOwner,
            nftContract,
            tokenId,
            _signature
        );
        require(
            _marketOwner == signerOwner,
            "Marketplace4907: Invalid signature"
        );

        // clean up date before leasing
        _cleanData(nftContract, tokenId);

        payable(_marketOwner).transfer(_leasingFee);

        bytes32 leaseId = keccak256(
            abi.encodePacked(
                block.timestamp,
                nftContract,
                tokenId,
                availableFrom,
                availableTo
            )
        );

        _leasingMap[nftContract][tokenId] = Leasing(
            leaseId,
            msg.sender,
            nftContract,
            tokenId,
            price,
            availableFrom,
            availableTo
        );

        _nftsLeased.increment();
        EnumerableSet.add(_nftContractTokensMap[nftContract], tokenId); // add token to lease rented token of nft contract
        EnumerableSet.add(_nftContracts, nftContract); // add nftContract to lease tracked contract

        emit LeasingNFT(
            leaseId,
            IERC721(nftContract).ownerOf(tokenId),
            IERC4907Sample(nftContract).getOriginalNFTContract(),
            nftContract,
            tokenId,
            price,
            availableFrom,
            availableTo,
            name,
            description,
            imageURL
        );
    }

    function unleaseNFT(
        address nftContract,
        uint256 tokenId
    ) external virtual override nonReentrant {
        Leasing storage leasing = _leasingMap[nftContract][tokenId];
        require(
            leasing.owner != address(0),
            "Marketplace4907: You cannot unlease unleased nfts"
        );
        require(
            msg.sender == leasing.owner,
            "Marketplace4907: You are not allowed to unlease these Nfts"
        );
        delete _leasingMap[nftContract][tokenId];
        EnumerableSet.remove(_nftContractTokensMap[nftContract], tokenId); // add token to lease rented token of nft contract
        EnumerableSet.remove(_nftContracts, nftContract); // add nftContract to lease tracked contract
        emit UnleaseNFT(nftContract, tokenId);
    }

    /**
     * @dev See {IMarketplace-rentNFT}.
     */
    function rentNFT(
        address nftContract,
        uint256 tokenId,
        uint256 startDate,
        uint256 endDate
    ) public payable virtual override nonReentrant {
        Leasing storage leasing = _leasingMap[nftContract][tokenId];
        bytes32 leaseId = leasing.leaseId;
        uint256 price = leasing.price;
        require(
            isRentableNFT(nftContract),
            "Marketplace4907: Contract is not an ERC4907"
        );
        require(
            msg.sender != IERC721(nftContract).ownerOf(tokenId),
            "Marketplace4907: You can't rent your own token"
        );
        require(
            startDate >= block.timestamp,
            "Marketplace4907: Rental period cannot be in the past"
        );
        require(
            endDate <= leasing.availableTo,
            "Marketplace4907: Rental period exceeds max date rentable"
        );
        require(
            startDate >= leasing.availableFrom,
            "Marketplace4907: Rental period less than min date rentable"
        );
        require(
            msg.value >= leasing.price,
            "Marketplace4907: Not enough money to cover rental period"
        );

        // Update rent info
        IERC4907(nftContract).setUser(tokenId, msg.sender, startDate, endDate);
        uint8 rentId = _numberOfRentMap[nftContract][tokenId];
        _rentingMap[nftContract][tokenId][rentId] = Renting(
            leasing.leaseId,
            msg.sender,
            nftContract,
            tokenId,
            startDate,
            endDate,
            leasing.price
        );
        _numberOfRentMap[nftContract][tokenId]++;

        payable(leasing.owner).transfer(leasing.price * 1e18);

        delete _leasingMap[nftContract][tokenId];
        EnumerableSet.remove(_nftContractTokensMap[nftContract], tokenId); // add token to lease rented token of nft contract
        EnumerableSet.remove(_nftContracts, nftContract); // add nftContract to lease tracked contract

        emit RentingNFT(
            leaseId,
            rentId,
            IERC4907Sample(nftContract).getOriginalNFTContract(),
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            nftContract,
            tokenId,
            startDate,
            endDate,
            price,
            block.timestamp
        );
    }

    /**
     * @dev See {IMarketplace-isRentableNFT}.
     */
    function isRentableNFT(
        address nftContract
    ) public view virtual override returns (bool) {
        bool _isRentable = false;
        bool _isNFT = false;
        try
            IERC165(nftContract).supportsInterface(type(IERC4907).interfaceId)
        returns (bool rentable) {
            _isRentable = rentable;
        } catch {
            return false;
        }
        try
            IERC165(nftContract).supportsInterface(type(IERC721).interfaceId)
        returns (bool nft) {
            _isNFT = nft;
        } catch {
            return false;
        }
        return _isRentable && _isNFT;
    }

    /**
     * @dev See {IMarketplace-getAllLeasings}.
     */
    function getAllLeasings()
        public
        view
        virtual
        override
        returns (Leasing[] memory)
    {
        Leasing[] memory leasings = new Leasing[](_nftsLeased.current()); // Khởi tạo mảng với size = số nft đã lease
        uint256 leasingsIndex = 0;
        address[] memory nftContracts = EnumerableSet.values(_nftContracts);
        for (uint256 i = 0; i < nftContracts.length; i++) {
            address nftAddress = nftContracts[i];
            uint256[] memory tokens = EnumerableSet.values(
                _nftContractTokensMap[nftAddress]
            );
            for (uint256 j = 0; j < tokens.length; j++) {
                leasings[leasingsIndex] = _leasingMap[nftAddress][tokens[j]];
                leasingsIndex++;
            }
        }
        return leasings;
    }

    /**
     * @dev See {IMarketplace-getLeasingTime}.
     */
    function getLeasingTime(
        address nftContract,
        uint256 tokenId
    ) public view virtual override returns (uint256, uint256) {
        uint256 availableFrom = _leasingMap[nftContract][tokenId].availableFrom;
        uint256 availableTo = _leasingMap[nftContract][tokenId].availableTo;
        return (availableFrom, availableTo);
    }

    /**
     * @dev See {IMarketplace-getLeasingFee}.
     */
    function getLeasingFee() public view virtual override returns (uint256) {
        return _leasingFee;
    }

    function setLeasingFee(uint256 newFee) external onlyOwner {
        _leasingFee = newFee;
    }

    /// @notice function to get leasing fee
    function _isDuplicateTimeWithOthers(
        address nftContract,
        uint256 tokenId,
        uint256 startDate,
        uint256 endDate
    ) internal view returns (bool) {
        uint8 numberOfRent = _numberOfRentMap[nftContract][tokenId];
        bool isDuplicateTime = false;

        for (uint8 i = 0; i < numberOfRent; i++) {
            uint256 startDateOfCurrentRent = _rentingMap[nftContract][tokenId][
                i
            ].startDate;
            uint256 endDateOfCurrentRent = _rentingMap[nftContract][tokenId][i]
                .endDate;

            if (
                (endDate <= startDateOfCurrentRent &&
                    startDate <= endDateOfCurrentRent) ||
                (startDate >= endDateOfCurrentRent &&
                    startDate > startDateOfCurrentRent)
            ) {
                isDuplicateTime = false;
            } else {
                isDuplicateTime = true;
                break;
            }
        }
        return isDuplicateTime;
    }

    // @notice function to clean up data before leasing
    /// @param nftContract  Contract address of NFT
    /// @param tokenId  ID of Token
    function _cleanData(address nftContract, uint256 tokenId) internal {
        uint8 numberOfRent = _numberOfRentMap[nftContract][tokenId];
        for (uint8 i = 0; i <= numberOfRent; i++) {
            delete _rentingMap[nftContract][tokenId][i];
        }
        _numberOfRentMap[nftContract][tokenId] = 0;
    }
}
