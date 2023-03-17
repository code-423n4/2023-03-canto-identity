# Canto Identity Subprotocols contest details
- Total Prize Pool: $36,500
  - HM awards: $25,500
  - QA report awards: $3,000
  - Gas report awards: $1,500
  - Judge + presort awards: 6,000
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-03-canto-identity-subprotocols-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts March 17, 2023 20:00 UTC
- Ends March 20, 2023 20:00 UTC

## Automated Findings / Publicly Known Issues

Automated findings output for the contest can be found [here](https://gist.github.com/ahmedovv123/ac550b389bcbe21043c613e6c6c1b563) within an hour of contest opening.

*Note for C4 wardens: Anything included in the automated findings output is considered a publicly known issue and is ineligible for awards.*

# Overview

The audit covers three subprotocols for the Canto Identity Protocol:
- Canto Bio Protocol: Allows the association of a biography to an identity
- Canto Profile Picture Protocol: Allows the association of a profile picture (arbitrary NFT) to an identity
- Canto Namespace Protocol: A subprotocol for minting names from tiles (characters in a specific font).

Each subprotocol is contained in a folder (`canto-bio-protocol`, `canto-namespace-protocol`, `canto-pfp-protocol`) and there is a `README` in every folder that describes the protocol in more detail.

# Scope

### Files in scope
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (4)_|
|[canto-pfp-protocol/src/ProfilePicture.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-pfp-protocol/src/ProfilePicture.sol)|[58](#nowhere "(nSLOC:58, SLOC:58, Lines:106)")|Profile Picture subprotocol NFT: Allows to reference an NFT that is owned by the user (the holder of the canto identity NFT that is associated with this PFP NFT). &nbsp;&nbsp;[100.00%](#nowhere "(Hit:20 / Total:20)")| [`solmate/*`](https://github.com/transmissions11/solmate)|
|[canto-bio-protocol/src/Bio.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-bio-protocol/src/Bio.sol) [🖥](#nowhere "Uses Assembly")|[94](#nowhere "(nSLOC:94, SLOC:94, Lines:129)")|Biography subprotocol NFT: Allows to mint an NFT with an arbitrary biography. &nbsp;&nbsp;[100.00%](#nowhere "(Hit:38 / Total:38)")| [`solmate/*`](https://github.com/transmissions11/solmate) [`solady/*`](https://github.com/Vectorized/solady)|
|[canto-namespace-protocol/src/Namespace.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Namespace.sol) [🖥](#nowhere "Uses Assembly")|[141](#nowhere "(nSLOC:141, SLOC:141, Lines:209)")|Namespace subprotocol NFT: Represents a name with characters in different fonts. &nbsp;&nbsp;-| [`solmate/*`](https://github.com/transmissions11/solmate) [`solady/*`](https://github.com/Vectorized/solady)|
|[canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol) [🧮](#nowhere "Uses Hash-Functions")|[180](#nowhere "(nSLOC:175, SLOC:180, Lines:279)")|Namespace NFTs are fused with trays that are bought (or traded on the secondary market). &nbsp;&nbsp;-| [`erc721a/*`](https://github.com/chiru-labs/ERC721A) [`solmate/*`](https://github.com/transmissions11/solmate) [`solady/*`](https://github.com/Vectorized/solady)|
|_Libraries (1)_|
|[canto-namespace-protocol/src/Utils.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Utils.sol) [Σ](#nowhere "Unchecked Blocks")|[214](#nowhere "(nSLOC:206, SLOC:214, Lines:283)")|Utilities for string/SVG manipulations that are used by the Namespace and Tray contract. &nbsp;&nbsp;-| [`solmate/*`](https://github.com/transmissions11/solmate)|
|Total (over 5 files):| [687](#nowhere "(nSLOC:674, SLOC:687, Lines:1006)") |[100.00%](#nowhere "Hit:58 / Total:58")|


### All other source contracts (not in scope)
|File|[SLOC](#nowhere "(nSLOC, SLOC, Lines)")|Description and [Coverage](#nowhere "(Lines hit / Total)")|Libraries|
|:-|:-:|:-|:-|
|_Contracts (3)_|
|[canto-identity-protocol/src/AddressRegistry.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/AddressRegistry.sol)|[47](#nowhere "(nSLOC:47, SLOC:47, Lines:93)")|-| [`solmate/*`](https://github.com/transmissions11/solmate)|
|[canto-identity-protocol/src/SubprotocolRegistry.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/SubprotocolRegistry.sol)|[64](#nowhere "(nSLOC:57, SLOC:64, Lines:113)")|-| [`solmate/*`](https://github.com/transmissions11/solmate)|
|[canto-identity-protocol/src/CidNFT.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/CidNFT.sol)|[300](#nowhere "(nSLOC:256, SLOC:300, Lines:447)")|-| [`solmate/*`](https://github.com/transmissions11/solmate)|
|Total (over 3 files):| [411](#nowhere "(nSLOC:360, SLOC:411, Lines:653)") |-|


## External imports
* **erc721a/ERC721A.sol**
  * [canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol)
* **solady/utils/Base64.sol**
  * [canto-bio-protocol/src/Bio.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-bio-protocol/src/Bio.sol)
  * [canto-namespace-protocol/src/Namespace.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Namespace.sol)
  * [canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol)
* **solmate/auth/Owned.sol**
  * ~~[canto-identity-protocol/src/CidNFT.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/CidNFT.sol)~~
  * [canto-namespace-protocol/src/Namespace.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Namespace.sol)
  * [canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol)
* **solmate/tokens/ERC20.sol**
  * ~~[canto-identity-protocol/src/CidNFT.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/CidNFT.sol)~~
  * ~~[canto-identity-protocol/src/SubprotocolRegistry.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/SubprotocolRegistry.sol)~~
  * [canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol)
* **solmate/tokens/ERC721.sol**
  * [canto-bio-protocol/src/Bio.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-bio-protocol/src/Bio.sol)
  * ~~[canto-identity-protocol/src/AddressRegistry.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/AddressRegistry.sol)~~
  * ~~[canto-identity-protocol/src/CidNFT.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/CidNFT.sol)~~
  * ~~[canto-identity-protocol/src/SubprotocolRegistry.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/SubprotocolRegistry.sol)~~
  * [canto-namespace-protocol/src/Namespace.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Namespace.sol)
  * [canto-pfp-protocol/src/ProfilePicture.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-pfp-protocol/src/ProfilePicture.sol)
* **solmate/utils/LibString.sol**
  * [canto-bio-protocol/src/Bio.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-bio-protocol/src/Bio.sol)
  * [canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol)
  * [canto-namespace-protocol/src/Utils.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Utils.sol)
* **solmate/utils/SafeTransferLib.sol**
  * ~~[canto-identity-protocol/src/CidNFT.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/CidNFT.sol)~~
  * ~~[canto-identity-protocol/src/SubprotocolRegistry.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-identity-protocol/src/SubprotocolRegistry.sol)~~
  * [canto-namespace-protocol/src/Tray.sol](https://github.com/code-423n4/2023-03-canto-identity/blob/main/canto-namespace-protocol/src/Tray.sol)

# Additional Context

All three subprotocols are Canto Identity Protocol subprotocols, so it might be helpful to look at this codebase to understand the subprotocols better. The code (folder `canto-identity-protocol`) was already audited in a previous audit and is out of scope for this audit. It is only included as additional context.


## Scoping Details 
```
- If you have a public code repo, please share it here:  
- How many contracts are in scope?:   5
- Total SLoC for these contracts?:  687
- How many external imports are there?: 14  
- How many separate interfaces and struct definitions are there for the contracts within scope?:  1
- Does most of your code generally use composition or inheritance?:   Inheritance
- How many external calls?:   5
- What is the overall line coverage percentage provided by your tests?:  100
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: true  
- Please describe required context:   Understanding Canto Identity Protocol (which was previously audited) is helpful, as these are subprotocols for it. But it is not strictly required
- Does it use an oracle?:  No
- Does the token conform to the ERC20 standard?:  
- Are there any novel or unique curve logic or mathematical models?: No
- Does it use a timelock function?: No 
- Is it an NFT?: Yes
- Does it have an AMM?:   No
- Is it a fork of a popular project?:  false 
- Does it use rollups?:   false
- Is it multi-chain?:  false
- Does it use a side-chain?: false
```

# Tests


To run the tests including a gas report, run the following command in every folder (`canto-bio-protocol`, `canto-namespace-protocol`, `canto-pfp-protocol`):
```
npm install && forge test --gas-report
```

slither works without problems in `canto-bio-protocol` and `canto-pfp-protocol`, but cannot analyze the code in `canto-namespace-protocol` because of the following error:
> unresolved reference to identifier _BITMASK_ADDRESS

## Quickstart command
`rm -Rf 2023-03-canto-identity || true && git clone https://github.com/code-423n4/2023-03-canto-identity.git -j8 --recurse-submodules && cd 2023-03-canto-identity && foundryup && cd canto-bio-protocol && npm install && forge test --gas-report && cd .. && cd canto-namespace-protocol && npm install && forge test --gas-report && cd .. && cd canto-pfp-protocol && npm install && forge test --gas-report && cd .. `
