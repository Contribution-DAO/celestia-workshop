// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPublicERC20Only1 is ERC20, Ownable {
    mapping(address => bool) public isPublicMinted;
    constructor(
        address initialOwner
    ) ERC20("My Cool Token", "MCT") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function publicMint() public {
        require(!isPublicMinted[msg.sender], "Already minted");
        isPublicMinted[msg.sender] = true;
        _mint(msg.sender, 1 ether);
    }
}
