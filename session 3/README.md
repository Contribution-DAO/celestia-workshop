## What is a DeFi Vault?

**A smart contract that pools assets and manages them automatically**

```
Traditional Finance          DeFi Vault
┌──────────────┐            ┌──────────────┐
│   Bank       │            │ Smart        │
│   Account    │    →       │ Contract     │
│              │            │ (Automated)  │
└──────────────┘            └──────────────┘
     Manual                     Automated
     Fees: High                 Fees: Low
     Access: Limited            Access: 24/7
```

**Key Features:**

- Automated asset management
- Transparent operations
- Share-based ownership

**The Problem:** Before standardization, every vault had different interfaces!

---

## How Vaults Work: The Flow

```
    USER                    VAULT                   STRATEGIES
      │                       │                          │
      │   1. Deposit 100 DAI  │                          │
      ├──────────────────────>│                          │
      │                       │   2. Deploy to Strategy  │
      │                       ├─────────────────────────>│
      │   3. Get 100 Shares   │                          │
      │<──────────────────────┤                          │
      │                       │   4. Generate Yield      │
      │                       │<─────────────────────────┤
      │   5. Redeem Shares    │                          │
      ├──────────────────────>│                          │
      │                       │   6. Withdraw Assets     │
      │                       ├─────────────────────────>│
      │   7. Get 110 DAI      │                          │
      │<──────────────────────┤   (10% profit!)          │
```

**You deposit assets → Get shares → Vault earns yield → Redeem for more assets**

---

# PART 1: DeFi Vault Standards

## Section A: ERC-4626 Fundamentals

---

## ERC-4626: The Problem & Solution

**The Problem Before ERC-4626:**

```
Every Protocol = Different Interface
┌─────────────────────────────────────┐
│ Yearn:  deposit() → yTokens         │
│ Aave:   supply() → aTokens          │
│ Compound: mint() → cTokens          │
│ Curve:  add_liquidity() → LP tokens│
└─────────────────────────────────────┘
Result: Developers build custom adapters
        for EACH vault = Time + Cost + Errors
```

**The Solution: ERC-4626**

```
┌─────────────────────────────────────┐
│      ONE Standard Interface         │
│  • deposit(assets) → shares         │
│  • redeem(shares) → assets          │
│  • totalAssets()                    │
│  • convertToShares()                │
└─────────────────────────────────────┘
Build once → Works with ALL vaults!
```

**Benefits:** ✓ Interoperability ✓ Reduced complexity ✓ Better security ✓ Composability

---

## ERC-4626: Share Calculation Formula

**How shares are calculated:**

```
                    assets × totalSupply
shares = ──────────────────────────────────
                     totalAssets
```

**Step-by-Step Example:**

```
Day 1: Initial Deposit
┌────────────────────────────────────────┐
│ Vault: 1,000 DAI, 1,000 shares        │
│ Rate: 1 DAI = 1 share                 │
└────────────────────────────────────────┘
You deposit: 100 DAI
Calculation: (100 × 1,000) / 1,000 = 100 shares
You receive: 100 shares ✓

Day 365: After Earning 10% Yield
┌────────────────────────────────────────┐
│ Vault: 1,100 DAI, 1,100 shares        │
│ Rate: 1 DAI = 1 share (still)         │
└────────────────────────────────────────┘
You redeem: 100 shares
Calculation: (100 × 1,100) / 1,100 = 100 DAI
You receive: 100 DAI
Your profit: 10 DAI (10% APY) 🎉
```

**Key Rule:** Always rounds DOWN (protects the vault & other users)

---

## Simple ERC-4626 Vault Contract

**That's All You Need!**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract MyVault is ERC4626 {
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {}

    // Inherits everything:
    // - deposit()  ← Users deposit assets
    // - redeem()   ← Users get assets back
    // - mint()
    // - withdraw()
    // - All view functions
}
```

**OpenZeppelin handles all the complexity!**

Add your custom strategy logic as needed.

---

## ERC-4626 in Action: Complete Example

**Scenario: Stablecoin Yield Vault**

```
Step 1: Deploy
─────────────────────────────────────────
Asset: USDC
Share Token: yUSDC
Strategy: Lend to Aave at 5% APY

Step 2: User Alice Deposits
─────────────────────────────────────────
Alice deposits: 1,000 USDC
Vault state: 1,000 USDC, 1,000 yUSDC shares
Alice receives: 1,000 yUSDC shares

Step 3: Vault Deploys Strategy
─────────────────────────────────────────
Vault → Aave: Lend 1,000 USDC
Earning: 5% APY

Step 4: Time Passes (1 year)
─────────────────────────────────────────
Vault earns: 50 USDC from Aave
Total in vault: 1,050 USDC
Total shares: 1,000 yUSDC

Step 5: Alice Redeems
─────────────────────────────────────────
Alice redeems: 1,000 yUSDC
Calculation: (1,000 × 1,050) / 1,000 = 1,050
Alice receives: 1,050 USDC
Profit: 50 USDC (5% return) ✓
```

## Section B: Vault Extensions

---

## ERC-7540: Async Vaults Problem

**ERC-4626 Limitation: Must be INSTANT**

```
ERC-4626: Atomic Only
────────────────────────────────────
User: deposit()
     ↓ (same transaction)
Vault: mint shares → DONE ✓

Works great for:
✓ Lending protocols (instant)
✓ Liquidity pools (instant)
✓ Simple strategies (instant)

Doesn't work for:
❌ Real-world assets (days/weeks)
❌ Cross-chain bridges (minutes/hours)
❌ Liquid staking (7-21 day unbonding)
❌ Compliance workflows (KYC/AML delays)
```

**The Gap:** Many important use cases need TIME!

**ERC-7540 Solution:** Adds Request → Pending → Claimable → Claimed pattern

---

## ERC-7540: The Request Lifecycle

**Three-Stage Asynchronous Flow:**

```
STAGE 1: PENDING (Assets Locked)
════════════════════════════════════════════
User calls: requestDeposit(1000 USDC, user, user)
            ↓
         ┌─────────────┐
         │ 1000 USDC   │ ← Locked in contract
         │ LOCKED      │   RequestId: #42
         │ Status: ⏳  │
         └─────────────┘

Processing: Minutes to weeks depending on use case
• RWAs: 7-30 days (legal/compliance)
• Bridges: 10-60 min (cross-chain)
• Staking: 7-21 days (unbonding)

         ↓ Time passes...

STAGE 2: CLAIMABLE (Ready!)
════════════════════════════════════════════
Check: claimableDepositRequest(42, user)
       Returns: 1000 assets ← Request fulfilled!

       ┌─────────────┐
       │ 1000 assets │
       │ ✅ READY    │   User can now claim
       │ Status: ✓   │
       └─────────────┘

         ↓ User claims

STAGE 3: CLAIMED (Complete)
════════════════════════════════════════════
User calls: deposit(1000, user, user)
            ↓
         ┌─────────────┐
         │ 1000 shares │ ← Shares received!
         │ RECEIVED ✅ │   Can trade/transfer
         │ Status: Done│
         └─────────────┘
```

---

## ERC-7540: Real-World Example

**Use Case: Tokenized Real Estate Vault**

```
Day 1 - User Request
────────────────────────────────────────
Bob: requestDeposit(100,000 USDC)
     → RequestId: #15
     → 100k USDC locked in contract
     Status: ⏳ PENDING

Days 2-7 - Off-Chain Processing
────────────────────────────────────────
• Legal verification
• Property acquisition
• Title transfer
• Compliance checks
Status: Still ⏳ PENDING

Day 8 - Ready to Claim
────────────────────────────────────────
claimableDepositRequest(#15, Bob)
→ Returns: 100,000 assets
Status: ✅ CLAIMABLE

Day 8 - Bob Claims
────────────────────────────────────────
Bob: deposit(100,000, Bob, Bob)
     → Receives: 100,000 property vault shares
     → Can now trade, transfer, or hold
Status: ✅ CLAIMED
```

**Key Insight:** ERC-7540 bridges DeFi and Real-World Assets!

---

## Section C: Standards Synthesis

## When to Use Each Standard

**Decision Framework:**

```
Your Use Case
     │
     ├─ Need time delays?
     │  (RWAs, bridges, staking)
     │  YES → Use ERC-7540
     │  NO ↓
     │
     └─ Standard instant vault
        → Use ERC-4626

```

**Comparison Table:**

| Feature        | ERC-4626 | ERC-7540 |
| -------------- | -------- | -------- |
| **Timing**     | Instant  | Async    |
| **Assets**     | Single   | Single   |
| **Complexity** | Simple   | Medium   |
| **Best For**   | DeFi     | RWAs     |

---

## Resources

**Vault Standards:**

- ERC-4626 Spec: https://eips.ethereum.org/EIPS/eip-4626
- ERC-7540 Spec: https://eips.ethereum.org/EIPS/eip-7540
- OpenZeppelin Docs: https://docs.openzeppelin.com/contracts/5.x/erc4626

---
