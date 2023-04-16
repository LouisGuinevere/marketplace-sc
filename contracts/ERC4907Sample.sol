// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IMarketplace4907.sol";
import "./ERC4907.sol";
import "./IERC4907Sample.sol";

contract ERC4907Sample is ERC4907, IERC4907Sample {
    address private _marketplaceContract;
    address private _originalNFTContract;
    address private _vendor;

    constructor(
        address marketplaceContract,
        address originalNFTContract,
        string memory name,
        string memory symbol
    ) ERC4907(name, symbol) {
        _marketplaceContract = marketplaceContract;
        _originalNFTContract = originalNFTContract;
        _vendor = msg.sender;
        _mint(msg.sender, 0);
        _mint(msg.sender, 1);
    }

    function mint(uint256 tokenId) public {
        require(
            msg.sender == IERC721(_originalNFTContract).ownerOf(tokenId),
            "You have no permission to mint NFT"
        );
        IERC721(_originalNFTContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        _mint(msg.sender, tokenId);
        setApprovalForAll(_marketplaceContract, true); // use to call IERC4907(nftContract).setUser(tokenId, msg.sender, expires);
    }

    function withdrawRealNft(uint256 tokenId) external {
        require(
            msg.sender == ownerOf(tokenId),
            "You have no permission to withdraw NFT"
        );

        // ensure NFT can not withdraw when leasing
        (uint256 leasingFrom, uint256 leasingTo) = IMarketplace4907(
            _marketplaceContract
        ).getLeasingTime(address(this), tokenId);
        require(
            block.timestamp < leasingFrom || block.timestamp > leasingTo,
            "NFT is being leased!"
        );

        // transfer NFT from contract to
        IERC721(_originalNFTContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function getOriginalNFTContract()
        public
        view
        virtual
        override
        returns (address)
    {
        return _originalNFTContract;
    }

    function getVendor() public view virtual override returns (address) {
        return _vendor;
    }
}
