// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Sample is ERC721, Ownable {

    Counters.Counter idCounter;

    constructor() ERC721("League Of Legends", "LOL") {
        _mint(msg.sender, 0);
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
        _mint(msg.sender, 3);
        _mint(msg.sender, 4);
        _mint(msg.sender, 5);
        _mint(msg.sender, 6);
        _mint(msg.sender, 7);
        _mint(msg.sender, 8);
        _mint(msg.sender, 9);
        Counters.increment(idCounter);
    }

    function mint(address owner) external onlyOwner() {
        _mint(owner, Counters.current(idCounter));
        Counters.increment(idCounter);
    }
}