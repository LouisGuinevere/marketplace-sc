// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC5006Sample.sol";
import "./IMarketplace5006.sol";
import "./IERC5006.sol";

contract Marketplace5006 is IMarketplace5006, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address private _marketOwner;
    uint256 private _leasingFee = 1 ether;
    Counters.Counter private _lotsLeased;

    mapping(address => mapping(bytes32 => Leasing)) private _leasingMap;
    mapping(address => mapping(bytes32 => mapping(uint8 => Renting))) _rentingMap;
    mapping(address => mapping(bytes32 => uint8)) public _numberOfRentMap;

    constructor() {
        _marketOwner = msg.sender;
    }

    function signatureWallet(
        address wallet,
        address nftContract,
        uint256 tokenId,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, nftContract, tokenId)),
                _signature
            );
    }

    function withdrawBalance() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function leaseNFT(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 availableFrom,
        uint256 availableTo,
        string memory name,
        string memory description,
        string memory imageURL,
        bytes memory _signature
    ) external payable returns (bytes32 leaseId) {
        require(
            isRentableNFT(nftContract),
            "Marketplace5006: Contract is not a rentable nft contract"
        );
        require(
            amount != 0,
            "Marketplace5006: Lease amount cannot be equal to 0"
        );
        address signerOwner = signatureWallet(
            _marketOwner,
            nftContract,
            tokenId,
            _signature
        );
        require(
            _marketOwner == signerOwner,
            "Marketplace5006: Invalid signature"
        );
        require(
            msg.value >= _leasingFee,
            "Marketplace5006: Not enough ether for leasing fee"
        );
        require(
            availableFrom >= block.timestamp,
            "Marketplace5006: Start date cannot be in the past"
        );
        require(
            availableTo > availableFrom,
            "Marketplace5006: End date cannot be before the start date"
        );
        require(
            amount <=
                IERC1155(nftContract).balanceOf(msg.sender, tokenId) -
                    IERC5006(nftContract).leasedBalanceOf(
                        msg.sender,
                        tokenId,
                        availableFrom
                    ),
            "Marketplace5006: You dont have enough NFTs to lease"
        );
        payable(_marketOwner).transfer(_leasingFee);
        leaseId = keccak256(
            abi.encodePacked(
                block.timestamp,
                nftContract,
                _lotsLeased.current(),
                availableFrom,
                availableTo
            )
        );
        _leasingMap[nftContract][leaseId] = Leasing(
            leaseId,
            msg.sender,
            nftContract,
            tokenId,
            amount,
            price,
            availableFrom,
            availableTo
        );
        _lotsLeased.increment();
        IERC5006Sample(nftContract).updateLeasedAmount(
            leaseId,
            msg.sender,
            tokenId,
            amount,
            availableTo
        );
        emit LeasingNFT(
            leaseId,
            msg.sender,
            IERC5006Sample(nftContract).getOriginalNFTContract(),
            nftContract,
            tokenId,
            amount,
            price,
            availableFrom,
            availableTo,
            name,
            description,
            imageURL
        );
        return leaseId;
    }

    function unleaseNFT(address nftContract, bytes32 leaseId) external {
        Leasing memory leasing = _leasingMap[nftContract][leaseId];
        require(
            leasing.owner != address(0),
            "Marketplace5006: You cannot unlease unleased nfts"
        );
        require(
            leasing.owner != msg.sender,
            "Marketplace5006: You are not allowed to unlease these nfts"
        );
        delete _leasingMap[nftContract][leaseId];
        IERC5006Sample(nftContract).unleaseNftAmount(
            leaseId,
            msg.sender,
            leasing.tokenId,
            leasing.amount
        );
        emit UnleaseNFT(nftContract, leaseId);
    }

    function rentNFT(
        address nftContract,
        bytes32 leaseId,
        uint256 startDate,
        uint256 endDate
    ) external payable {
        require(
            isRentableNFT(nftContract),
            "Marketplace5006: Contract is not an ERC5006"
        );
        Leasing memory leasing = _leasingMap[nftContract][leaseId];
        require(
            leasing.owner != msg.sender,
            "Marketplace5006: Cannot rent your own nfts"
        );
        require(
            startDate >= block.timestamp,
            "Marketplace5006: Rental period cannot be in the past"
        );
        require(
            leasing.availableFrom <= startDate &&
                leasing.availableTo >= endDate,
            "Marketplace5006: Invalid rental period"
        );
        require(
            msg.value >= leasing.price,
            "Marketplace5006: Not enough money to cover rental period"
        );
        payable(leasing.owner).transfer(leasing.price * 1e18);
        IERC5006(nftContract).createUserRecord(
            leasing.owner,
            msg.sender,
            leasing.tokenId,
            leasing.amount,
            startDate,
            endDate
        );
        _numberOfRentMap[nftContract][leaseId]++;
        uint8 rentId = _numberOfRentMap[nftContract][leaseId];
        _rentingMap[nftContract][leaseId][rentId] = Renting(
            leasing.leaseId,
            msg.sender,
            nftContract,
            startDate,
            endDate,
            leasing.price
        );

        emit RentingNFT(
            leasing.leaseId,
            rentId,
            IERC5006Sample(nftContract).getOriginalNFTContract(),
            leasing.owner,
            msg.sender,
            nftContract,
            leasing.tokenId,
            leasing.amount,
            startDate,
            endDate,
            leasing.price,
            block.timestamp
        );
    }

    function isRentableNFT(
        address nftContract
    ) public view override returns (bool) {
        bool _isRentable = false;
        bool _isValidNFT = false;
        try
            IERC165(nftContract).supportsInterface(type(IERC5006).interfaceId)
        returns (bool rentable) {
            _isRentable = rentable;
        } catch {
            return false;
        }
        try
            IERC165(nftContract).supportsInterface(type(IERC1155).interfaceId)
        returns (bool nft) {
            _isValidNFT = nft;
        } catch {
            return false;
        }
        return _isRentable && _isValidNFT;
    }

    function getLeasingTime(
        address nftContract,
        bytes32 leaseId
    ) public view override returns (uint256, uint256) {
        uint256 availableFrom = _leasingMap[nftContract][leaseId].availableFrom;
        uint256 availableTo = _leasingMap[nftContract][leaseId].availableTo;
        return (availableFrom, availableTo);
    }

    function getLeasingFee() public view returns (uint256) {
        return _leasingFee;
    }

    function setLeasingFee(uint256 newFee) external onlyOwner {
        _leasingFee = newFee;
    }

    function _cleanData(address nftContract, bytes32 leaseId) internal {
        uint8 numberOfRent = _numberOfRentMap[nftContract][leaseId];
        for (uint8 i = 0; i <= numberOfRent; i++) {
            delete _rentingMap[nftContract][leaseId][i];
        }
        _numberOfRentMap[nftContract][leaseId] = 0;
    }
}
