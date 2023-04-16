// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IMarketplace721.sol";

contract Marketplace721 is Ownable, IMarketplace721 {
    uint256 private _listingFee = 1 ether;
    address private _marketOwner;

    //mapping from nft contract address to tokenId to sellingInfo
    mapping(address => mapping(uint256 => ListedNFT)) listedNftList;

    constructor() {
        _marketOwner = msg.sender;
    }

    function _verifyCollection(
        address walletAddress,
        address nftContractAddress,
        uint256 tokenId,
        bytes memory signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encode(walletAddress, nftContractAddress, tokenId)
                ),
                signature
            );
    }

    function withdrawBalance() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getListingFee() external view returns (uint256) {
        return _listingFee;
    }

    function setListingFee(uint256 newFee) external onlyOwner {
        _listingFee = newFee;
    }

    function getListedNFT(
        address nftContractAddress,
        uint256 tokenId
    ) external view returns (address, address, uint256, uint256, bool) {
        ListedNFT memory nft = listedNftList[nftContractAddress][tokenId];
        return (nftContractAddress, nft.owner, tokenId, nft.price, nft.status);
    }

    function listNFT(
        address nftContractAddress,
        uint256 tokenId,
        uint256 price,
        string memory name,
        string memory description,
        string memory imageURL,
        bytes memory signature
    ) external payable {
        require(
            msg.value >= _listingFee,
            "Marketplace: You have to pay us some ether for listing nft"
        );
        require(
            _verifyCollection(
                msg.sender,
                nftContractAddress,
                tokenId,
                signature
            ) == _marketOwner,
            "Marketplace: You are listing a nft belongs to an unregistered collection"
        );
        require(
            IERC721(nftContractAddress).ownerOf(tokenId) == msg.sender,
            "Marketplace: You dont have permission to list this nft for sale"
        );
        require(price > 0, "Marketplace: You cannot sell this nft for free");
        require(
            listedNftList[nftContractAddress][tokenId].status == false,
            "Marketplace: You cannot list a listed nft"
        );

        listedNftList[nftContractAddress][tokenId] = ListedNFT(
            nftContractAddress,
            tokenId,
            msg.sender,
            price,
            true
        );

        emit ListingNFT(
            msg.sender,
            nftContractAddress,
            tokenId,
            price,
            name,
            description,
            imageURL,
            block.timestamp
        );
    }

    function unlistNFT(address nftContractAddress, uint256 tokenId) external {
        ListedNFT memory listedNft = listedNftList[nftContractAddress][tokenId];

        require(
            listedNft.status == true,
            "Marketplace: You cannot unlist an unlisted nft"
        );
        require(
            msg.sender == listedNft.owner,
            "Marketplace: You cannot unlist this nft"
        );

        delete (listedNft);

        emit UnlistNFT(
            msg.sender,
            nftContractAddress,
            tokenId,
            block.timestamp
        );
    }

    function buyNFT(
        address nftContractAddress,
        uint256 tokenId
    ) external payable {
        ListedNFT memory listedNft = listedNftList[nftContractAddress][tokenId];

        require(
            listedNft.status == true,
            "Marketplace: You cannot buy an unlisted/disabled nft"
        );
        require(
            listedNft.owner != msg.sender,
            "Marketplace: You cannot buy your own nft"
        );
        require(
            msg.value >= listedNft.price,
            "Marketplace: Not enough money to cover rental period"
        );

        payable(listedNft.owner).transfer(listedNft.price * 1e18);

        IERC721(nftContractAddress).safeTransferFrom(
            listedNft.owner,
            msg.sender,
            listedNft.tokenId
        );
        delete listedNftList[nftContractAddress][tokenId];

        emit BuyingNFT(
            msg.sender,
            listedNft.owner,
            nftContractAddress,
            listedNft.tokenId,
            listedNft.price,
            block.timestamp
        );
    }

    function _validateNftContract(
        address nftContractAddress
    ) internal view returns (bool) {
        bool _isRentable = false;
        bool _isNFT = false;
        try
            IERC721(nftContractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        returns (bool rentable) {
            _isRentable = rentable;
        } catch {
            return false;
        }
        try
            IERC721(nftContractAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        returns (bool nft) {
            _isNFT = nft;
        } catch {
            return false;
        }
        return _isRentable && _isNFT;
    }
}
