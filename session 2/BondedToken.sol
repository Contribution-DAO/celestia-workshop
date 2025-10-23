// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import the standard ERC20 contract
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title BondedToken
 * @dev This contract is both an ERC20 token and its own
 * linear bonding curve market.
 * Price = slope * totalSupply
 */
contract BondedToken is ERC20 {
    // --- Bonding Curve Parameters ---

    // We set a slope 'm' for our linear curve: P = m * S
    // Let's set slope m = 0.000001 ETH (which is 10^12 wei)
    // We use a numerator/denominator to handle 18 decimals of the token.
    uint256 public constant SLOPE_NUMERATOR = 10 ** 12; // 1e12 wei
    uint256 public constant SLOPE_DENOMINATOR = 10 ** 18; // 1 token (with 18 decimals)

    // --- Events ---
    event Bought(address indexed buyer, uint256 amount, uint256 ethPaid);
    event Sold(address indexed seller, uint256 amount, uint256 ethReceived);

    // --- Constructor ---
    constructor() ERC20("Bonded Token", "BOND") {}

    // --- View Functions (To check prices) ---

    /**
     * @dev Calculates the price IN WEI for the *next* token to be minted.
     * Price = (totalSupply * slope)
     */
    function getBuyPrice() public view returns (uint256) {
        // We use the 18-decimal supply from ERC20.
        // Price = (totalSupply() * 10**12) / 10**18
        return (totalSupply() * SLOPE_NUMERATOR) / SLOPE_DENOMINATOR;
    }

    /**
     * @dev Calculates the payout IN WEI for selling one token.
     * This is the price of the *previous* token.
     * Price = ( (totalSupply - 1) * slope )
     */
    function getSellPrice() public view returns (uint256) {
        require(totalSupply() > 0, "No tokens in supply to sell");
        uint256 oneToken = 1 * (10 ** decimals());
        // Price = ((totalSupply() - 1 token) * 10**12) / 10**18
        return
            ((totalSupply() - oneToken) * SLOPE_NUMERATOR) / SLOPE_DENOMINATOR;
    }

    // --- Core Functions (Buy & Sell) ---

    /**
     * @dev Buys exactly ONE token.
     * Must send the exact ETH value returned by getBuyPrice().
     *
     * NOTE: This is a simplified example. A real contract would
     * use an integral to calculate the price for *multiple* tokens.
     */
    function buy() public payable {
        uint256 price = getBuyPrice();
        require(msg.value == price, "Must send exact ETH price for 1 token");

        uint256 amount = 1 * (10 ** decimals()); // 1 token with 18 decimals
        _mint(msg.sender, amount);

        emit Bought(msg.sender, amount, msg.value);
    }

    /**
     * @dev Sells exactly ONE token.
     * You must first call 'approve(contract_address, amount)'
     *
     * NOTE: This is a simplified example.
     */
    function sell() public {
        uint256 amount = 1 * (10 ** decimals()); // 1 token
        uint256 payout = getSellPrice();

        // Burn 1 token from the caller
        _burn(msg.sender, amount);

        // Send them the ETH payout
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Failed to send ETH");

        emit Sold(msg.sender, amount, payout);
    }
}
