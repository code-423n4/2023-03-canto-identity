# AddressRegistry
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/AddressRegistry.sol)

Allows users to register their CID NFT


## State Variables
### cidNFT
Address of the CID NFT


```solidity
address public immutable cidNFT;
```


### cidNFTs
Stores the mappings of users to their CID NFT


```solidity
mapping(address => uint256) private cidNFTs;
```


## Functions
### constructor


```solidity
constructor(address _cidNFT);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFT`|`address`|Address of the CID NFT contract|


### register

Register a CID NFT to the address of the caller. NFT has to be owned by the caller

*Will overwrite existing registration if any exists*


```solidity
function register(uint256 _cidNFTID) external;
```

### remove

Remove the current registration of the caller


```solidity
function remove() external;
```

### getCID

Get the CID NFT ID that is registered for the provided user


```solidity
function getCID(address _user) external view returns (uint256 cidNFTID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_user`|`address`|Address to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`cidNFTID`|`uint256`|The registered CID NFT ID. 0 when no CID NFT is registered for the given address|


## Events
### CIDNFTAdded

```solidity
event CIDNFTAdded(address indexed user, uint256 indexed cidNFTID);
```

### CIDNFTRemoved

```solidity
event CIDNFTRemoved(address indexed user, uint256 indexed cidNFTID);
```

## Errors
### NFTNotOwnedByUser

```solidity
error NFTNotOwnedByUser(uint256 cidNFTID, address caller);
```

### NoCIDNFTRegisteredForUser

```solidity
error NoCIDNFTRegisteredForUser(address caller);
```

