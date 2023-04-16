// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Sample is ERC20, Ownable {
    constructor() ERC20("League of Legends Token", "LLT"){
        _mint(msg.sender, 100000000000000000000);
        _mint(0x5dffe253DC9A143b47Ae2696ac5C58b31425452C, 100000000000000000000);
    }

    function mint(address owner, uint256 amount) external onlyOwner() {
        require(owner != address(0), "ERC20Sample: Cannot mint for address 0");
        require(amount != 0, "ERC20Sample: Cannot mint 0 token");
        _mint(owner, amount);
    }
}