// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC1155Sample is ERC1155, Ownable {
    Counters.Counter idCounter;

    constructor() ERC1155("") {
        _mint(msg.sender, 0, 100, "");
        _mint(msg.sender, 1, 200, "");
        _mint(msg.sender, 2, 300, "");
        _mint(msg.sender, 3, 50, "");
        _mint(msg.sender, 4, 20, "");
        _mint(msg.sender, 5, 10, "");
    }

    function mint(
        address owner,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _mint(owner, tokenId, amount, "");
    }
}
