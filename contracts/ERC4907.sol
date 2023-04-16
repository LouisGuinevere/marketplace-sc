// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4907.sol";

contract ERC4907 is ERC721, IERC4907 {
    struct UserInfo {
        address user; // address of user role
        uint256 startDate; // unix timestamp, user expires
        uint256 endDate; // unix timestamp, user expires
    }

    mapping(uint256 => UserInfo) internal _users;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function setUser(
        uint256 tokenId,
        address user,
        uint256 startDate,
        uint256 endDate
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.startDate = startDate;
        info.endDate = endDate;
        emit UpdateUser(tokenId, user, startDate, endDate);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(
        uint256 tokenId
    ) public view virtual returns (address, uint256, uint256, uint256, bool) {
        if (
            (_users[tokenId].endDate >= block.timestamp * 1000) &&
            (_users[tokenId].startDate <= block.timestamp * 1000)
        ) {
            return (
                _users[tokenId].user,
                _users[tokenId].startDate,
                _users[tokenId].endDate,
                block.timestamp,
                (_users[tokenId].endDate >= block.timestamp) &&
                    (_users[tokenId].startDate <= block.timestamp)
            );
        } else {
            return (
                ownerOf(tokenId),
                _users[tokenId].startDate,
                _users[tokenId].endDate,
                block.timestamp,
                true
            );
        }
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(
        uint256 tokenId
    ) public view virtual returns (address, uint256, uint256) {
        return (
            _users[tokenId].user,
            _users[tokenId].startDate,
            _users[tokenId].endDate
        );
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
