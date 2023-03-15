# Canto Identity Subprotocols contest details
- Total Prize Pool: Sum of below awards
  - HM awards: XXX XXX
  - QA report awards: XXX XXX 
  - Gas report awards: XXX XXX 
  - Judge + presort awards: XXX XXX 
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-03-canto-identity-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts March 17, 2023 20:00 UTC
- Ends TBD XXX XXX XX 20:00 UTC

## Automated Findings / Publicly Known Issues

Automated findings output for the contest can be found [here](add link to report) within an hour of contest opening.

*Note for C4 wardens: Anything included in the automated findings output is considered a publicly known issue and is ineligible for awards.*

# Overview

The audit covers three subprotocols for the Canto Identity Protocol:
- Canto Bio Protocol: Allows the association of a biography to an identity
- Canto Profile Picture Protocol: Allows the association of a profile picture (arbitrary NFT) to an identity
- Canto Namespace Protocol: A subprotocol for minting names from tiles (characters in a specific font).

Each subprotocol is contained in a folder (`canto-bio-protocol`, `canto-namespace-protocol`, `canto-pfp-protocol`) and there is a `README` in every folder that describes the protocol in more detail.

# Scope


| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [canto-bio-protocol/src/Bio.sol](canto-bio-protocol/src/Bio.sol) | 94 | Biography subprotocol NFT: Allows to mint an NFT with an arbitrary biography. | [`solmate/*`](https://github.com/transmissions11/solmate), [`solady/*`](https://github.com/Vectorized/solady) |
| [canto-pfp-protocol/src/ProfilePicture.sol](canto-pfp-protocol/src/ProfilePicture.sol) | 58 | Profile Picture subprotocol NFT: Allows to reference an NFT that is owned by the user (the holder of the canto identity NFT that is associated with this PFP NFT). | [`solmate/*`](https://github.com/transmissions11/solmate) |
| [canto-namespace-protocol/src/Namespace.sol](canto-namespace-protocol/src/Namespace.sol) | 141 | Namespace subprotocol NFT: Represents a name with characters in different fonts. | [`solmate/*`](https://github.com/transmissions11/solmate), [`solady/*`](https://github.com/Vectorized/solady) |
| [canto-namespace-protocol/src/Tray.sol](canto-namespace-protocol/src/Tray.sol) | 180 | Namespace NFTs are fused with trays that are bought (or traded on the secondary market). | [`solmate/*`](https://github.com/transmissions11/solmate), [`solady/*`](https://github.com/Vectorized/solady) |
| [canto-namespace-protocol/src/Utils.sol](canto-namespace-protocol/src/Utils.sol) | 214 | Utilities for string/SVG manipulations that are used by the Namespace and Tray contract. | [`solmate/*`](https://github.com/transmissions11/solmate) |

## Out of scope

The canto identity protocol (folder `canto-identity-protocol`) was already audited in a previous audit and is out of scope for this audit. It is only included as additional context.

# Additional Context

All three subprotocols are Canto Identity Protocol subprotocols, so it might be helpful to look at this codebase to understand the subprotocols better.

## Scoping Details 
```
- If you have a public code repo, please share it here: - 
- How many contracts are in scope?: 5
- Total SLoC for these contracts?: 687 
- How many external imports are there?: 14 
- How many separate interfaces and struct definitions are there for the contracts within scope?: 1
- Does most of your code generally use composition or inheritance?: composition
- How many external calls?: 5 
- What is the overall line coverage percentage provided by your tests?: 100% 
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: No, but understanding canto identity protocol is helpful
- Please describe required context: The three NFTs are subprotocols for the canto identity protocol, which was previously audited and is also included for additional context.
- Does it use an oracle?: No
- Does the token conform to the ERC20 standard?: No
- Are there any novel or unique curve logic or mathematical models?: No
- Does it use a timelock function?: No
- Is it an NFT?: Yes
- Does it have an AMM?: No  
- Is it a fork of a popular project?: No  
- Does it use rollups?: No
- Is it multi-chain?: No
- Does it use a side-chain?: No
```

# Tests

*Provide every step required to build the project from a fresh git clone, as well as steps to run the tests with a gas report.* 

To run the tests including a gas report, run the following command in every folder (`canto-bio-protocol`, `canto-namespace-protocol`, `canto-pfp-protocol`):
```
npm install && forge test --gas-report
```

slither works without problems in `canto-bio-protocol` and `canto-pfp-protocol`, but cannot analyze the code in `canto-namespace-protocol` because of the following error:
> unresolved reference to identifier _BITMASK_ADDRESS