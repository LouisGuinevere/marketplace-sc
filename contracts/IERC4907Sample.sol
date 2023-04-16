// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC4907Sample {
    function getOriginalNFTContract() external view returns (address);

    function getVendor() external view returns (address);
}
