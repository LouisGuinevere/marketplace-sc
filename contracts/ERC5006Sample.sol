// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC5006.sol";
import "./IERC5006Sample.sol";
import "./IMarketplace5006.sol";

contract ERC5006Sample is ERC5006, IERC5006Sample {
    address private _marketplaceContract;
    address private _originalNFTContract;
    address private _vendor;
    Counters.Counter private _lotIds;

    constructor(address marketplaceContract, address originalNFTContract) {
        _marketplaceContract = marketplaceContract;
        _originalNFTContract = originalNFTContract;
        _vendor = msg.sender;
        _mint(msg.sender, 0, 20, "");
        _mint(msg.sender, 1, 20, "");
        _mint(msg.sender, 2, 20, "");
        _mint(msg.sender, 3, 20, "");
        _mint(msg.sender, 4, 20, "");
        _mint(msg.sender, 5, 20, "");
    }

    function mintRentableNfts(uint256 tokenId, uint256 amount) external {
        require(
            amount > 0,
            "ERC5006Sample: Mint amount must be greater than zero"
        );
        IERC1155(_originalNFTContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );
        _mint(msg.sender, tokenId, amount, "0x0");
        setApprovalForAll(_marketplaceContract, true);
    }

    function withdrawOriginalNfts(uint256 tokenId, uint256 amount) external {
        require(
            balanceOf(msg.sender, tokenId) -
                leasedBalanceOf(msg.sender, tokenId, block.timestamp) >=
                amount,
            "ERC5006Sample: User dont have enough amount of usable nfts to withdraw"
        );
        IERC1155(_originalNFTContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            "0x0"
        );
    }

    function withdrawableNftAmount(
        uint256 tokenId,
        uint256 time
    ) external view returns (uint256, uint256, uint256) {
        return (
            balanceOf(msg.sender, tokenId),
            leasedBalanceOf(msg.sender, tokenId, time),
            balanceOf(msg.sender, tokenId) -
                leasedBalanceOf(msg.sender, tokenId, time)
        );
    }

    function burn(uint256 tokenId, uint256 amount) external {
        _burn(msg.sender, tokenId, amount);
    }

    function updateLeasedAmount(
        bytes32 leaseId,
        address owner,
        uint256 tokenId,
        uint256 amount,
        uint256 endDate
    ) external override {
        require(
            msg.sender == _marketplaceContract,
            "ERC5006Sample: Only marketplace contract can execute this action"
        );
        require(
            amount > 0,
            "ERC5006Sample: Freeze amount must be greater than 0"
        );
        require(
            usableBalanceOf(owner, tokenId, block.timestamp) >= amount,
            "ERC5006Sample: Owner doesnt have enough nfts to be frozen"
        );
        LeasingSession memory leasingSession = LeasingSession(
            leaseId,
            amount,
            block.timestamp,
            endDate
        );
        _leased[tokenId][owner].push(leasingSession);
    }

    function unleaseNftAmount(
        bytes32 leaseId,
        address owner,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(
            msg.sender == _marketplaceContract,
            "ERC5006Sample: Only marketplace contract can execute this action"
        );
        require(amount > 0, "ERC5006Sample: Amount must be greater than 0");
        for (uint256 i = 0; i < _leased[tokenId][owner].length; i++) {
            if (_leased[tokenId][owner][i].leaseId == leaseId) {
                delete _leased[tokenId][owner][i].leaseId;
            }
        }
    }

    function getOriginalNFTContract() external view override returns (address) {
        return _originalNFTContract;
    }

    function getVendor() external view override returns (address) {
        return _vendor;
    }
}
