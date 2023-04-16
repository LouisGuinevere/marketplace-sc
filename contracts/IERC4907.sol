// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

interface IERC4907 {
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint256 startDate,
        uint256 endDate
    );

    function setUser(
        uint256 tokenId,
        address user,
        uint256 startDate,
        uint256 endDate
    ) external;

    function userOf(
        uint256 tokenId
    ) external view returns (address, uint256, uint256, uint256, bool);

    function userExpires(
        uint256 tokenId
    ) external view returns (address, uint256, uint256);
}
