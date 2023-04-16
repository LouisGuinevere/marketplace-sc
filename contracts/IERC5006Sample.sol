// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC5006Sample {
    function getOriginalNFTContract() external view returns (address);

    function getVendor() external view returns (address);

    function updateLeasedAmount(
        bytes32 leaseId,
        address owner,
        uint256 tokenId,
        uint256 amount,
        uint256 endDate
    ) external;

    function unleaseNftAmount(
        bytes32 leaseId,
        address owner,
        uint256 tokenId,
        uint256 amount
    ) external;
}
