# CidNFT
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/CidNFT.sol)

**Inherits:**
ERC721, ERC721TokenReceiver

CID NFTs are at the heart of the CID protocol. All key/values of subprotocols are associated with them.


## State Variables
### CID_FEE_BPS
Fee (in BPS) that is charged for every mint (as a percentage of the mint fee). Fixed at 10%.


```solidity
uint256 public constant CID_FEE_BPS = 1_000;
```


### cidFeeWallet
Wallet that receives CID fees


```solidity
address public immutable cidFeeWallet;
```


### note
Reference to the NOTE TOKEN


```solidity
ERC20 public immutable note;
```


### subprotocolRegistry
Reference to the subprotocol registry


```solidity
SubprotocolRegistry public immutable subprotocolRegistry;
```


### baseURI
Base URI of the NFT


```solidity
string public baseURI;
```


### numMinted
Counter of the minted NFTs

*Used to assign a new unique ID. The first ID that is assigned is 1, ID 0 is never minted.*


```solidity
uint256 public numMinted;
```


### cidData
Stores the references to subprotocol NFTs. Mapping nftID => subprotocol name => subprotocol data


```solidity
mapping(uint256 => mapping(string => SubprotocolData)) internal cidData;
```


## Functions
### constructor

Sets the name, symbol, baseURI, and the address of the auction factory


```solidity
constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address _cidFeeWallet,
    address _noteContract,
    address _subprotocolRegistry
) ERC721(_name, _symbol);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|Name of the NFT|
|`_symbol`|`string`|Symbol of the NFT|
|`_baseURI`|`string`|NFT base URI. {id}.json is appended to this URI|
|`_cidFeeWallet`|`address`|Address of the wallet that receives the fees|
|`_noteContract`|`address`|Address of the $NOTE contract|
|`_subprotocolRegistry`|`address`|Address of the subprotocol registry|


### tokenURI

Get the token URI for the provided ID


```solidity
function tokenURI(uint256 _id) public view override returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_id`|`uint256`|ID to retrieve the URI for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|tokenURI The URI of the queried token (path to a JSON file)|


### mint

Mint a new CID NFT

*An address can mint multiple CID NFTs, but it can only set one as associated with it in the AddressRegistry*


```solidity
function mint(bytes[] calldata _addList) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_addList`|`bytes[]`|An optional list of encoded parameters for add to add subprotocol NFTs directly after minting. The parameters should not include the function selector itself, the function select for add is always prepended.|


### add

Add a new entry for the given subprotocol to the provided CID NFT


```solidity
function add(
    uint256 _cidNFTID,
    string calldata _subprotocolName,
    uint256 _key,
    uint256 _nftIDToAdd,
    AssociationType _type
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFTID`|`uint256`|ID of the CID NFT to add the data to|
|`_subprotocolName`|`string`|Name of the subprotocol where the data will be added. Has to exist.|
|`_key`|`uint256`|Key to set. This value is only relevant for the AssociationType ORDERED (where a mapping int => nft ID is stored)|
|`_nftIDToAdd`|`uint256`|The ID of the NFT to add|
|`_type`|`AssociationType`|Association type (see AssociationType struct) to use for this data|


### remove

Remove / unset a key for the given CID NFT and subprotocol


```solidity
function remove(
    uint256 _cidNFTID,
    string calldata _subprotocolName,
    uint256 _key,
    uint256 _nftIDToRemove,
    AssociationType _type
) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFTID`|`uint256`|ID of the CID NFT to remove the data from|
|`_subprotocolName`|`string`|Name of the subprotocol where the data will be removed. Has to exist.|
|`_key`|`uint256`|Key to unset. This value is only relevant for the AssociationType ORDERED|
|`_nftIDToRemove`|`uint256`|The ID of the NFT to remove. Only needed for the AssociationType ACTIVE|
|`_type`|`AssociationType`|Association type (see AssociationType struct) to remove this data from|


### getOrderedData

Get the ordered data that is associated with a CID NFT / Subprotocol


```solidity
function getOrderedData(uint256 _cidNFTID, string calldata _subprotocolName, uint256 _key)
    external
    view
    returns (uint256 subprotocolNFTID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFTID`|`uint256`|ID of the CID NFT to query|
|`_subprotocolName`|`string`|Name of the subprotocol to query|
|`_key`|`uint256`|Key to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`subprotocolNFTID`|`uint256`|The ID of the NFT at the queried key. 0 if it does not exist|


### getPrimaryData

Get the primary data that is associated with a CID NFT / Subprotocol


```solidity
function getPrimaryData(uint256 _cidNFTID, string calldata _subprotocolName)
    external
    view
    returns (uint256 subprotocolNFTID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFTID`|`uint256`|ID of the CID NFT to query|
|`_subprotocolName`|`string`|Name of the subprotocol to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`subprotocolNFTID`|`uint256`|The ID of the primary NFT at the queried subprotocl / CID NFT. 0 if it does not exist|


### getActiveData

Get the active data list that is associated with a CID NFT / Subprotocol


```solidity
function getActiveData(uint256 _cidNFTID, string calldata _subprotocolName)
    external
    view
    returns (uint256[] memory subprotocolNFTIDs);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFTID`|`uint256`|ID of the CID NFT to query|
|`_subprotocolName`|`string`|Name of the subprotocol to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`subprotocolNFTIDs`|`uint256[]`|The ID of the primary NFT at the queried subprotocl / CID NFT. 0 if it does not exist|


### activeDataIncludesNFT

Check if a provided NFT ID is included in the active data list that is associated with a CID NFT / Subprotocol


```solidity
function activeDataIncludesNFT(uint256 _cidNFTID, string calldata _subprotocolName, uint256 _nftIDToCheck)
    external
    view
    returns (bool nftIncluded);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cidNFTID`|`uint256`|ID of the CID NFT to query|
|`_subprotocolName`|`string`|Name of the subprotocol to query|
|`_nftIDToCheck`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nftIncluded`|`bool`|True if the NFT ID is in the list|


### onERC721Received


```solidity
function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);
```

## Events
### OrderedDataAdded

```solidity
event OrderedDataAdded(
    uint256 indexed cidNFTID, string indexed subprotocolName, uint256 indexed key, uint256 subprotocolNFTID
);
```

### PrimaryDataAdded

```solidity
event PrimaryDataAdded(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
```

### ActiveDataAdded

```solidity
event ActiveDataAdded(
    uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID, uint256 arrayIndex
);
```

### OrderedDataRemoved

```solidity
event OrderedDataRemoved(
    uint256 indexed cidNFTID, string indexed subprotocolName, uint256 indexed key, uint256 subprotocolNFTID
);
```

### PrimaryDataRemoved

```solidity
event PrimaryDataRemoved(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
```

### ActiveDataRemoved

```solidity
event ActiveDataRemoved(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
```

## Errors
### TokenNotMinted

```solidity
error TokenNotMinted(uint256 tokenID);
```

### AddCallAfterMintingFailed

```solidity
error AddCallAfterMintingFailed(uint256 index);
```

### SubprotocolDoesNotExist

```solidity
error SubprotocolDoesNotExist(string subprotocolName);
```

### NFTIDZeroDisallowedForSubprotocols

```solidity
error NFTIDZeroDisallowedForSubprotocols();
```

### AssociationTypeNotSupportedForSubprotocol

```solidity
error AssociationTypeNotSupportedForSubprotocol(AssociationType associationType, string subprotocolName);
```

### NotAuthorizedForCIDNFT

```solidity
error NotAuthorizedForCIDNFT(address caller, uint256 cidNFTID, address cidNFTOwner);
```

### NotAuthorizedForSubprotocolNFT

```solidity
error NotAuthorizedForSubprotocolNFT(address caller, uint256 subprotocolNFTID);
```

### ActiveArrayAlreadyContainsID

```solidity
error ActiveArrayAlreadyContainsID(uint256 cidNFTID, string subprotocolName, uint256 nftIDToAdd);
```

### OrderedValueNotSet

```solidity
error OrderedValueNotSet(uint256 cidNFTID, string subprotocolName, uint256 key);
```

### PrimaryValueNotSet

```solidity
error PrimaryValueNotSet(uint256 cidNFTID, string subprotocolName);
```

### ActiveArrayDoesNotContainID

```solidity
error ActiveArrayDoesNotContainID(uint256 cidNFTID, string subprotocolName, uint256 nftIDToRemove);
```

## Structs
### IndexedArray
Array of uint256 values (NFT IDs) with additional position information NFT ID => (array pos. + 1)


```solidity
struct IndexedArray {
    uint256[] values;
    mapping(uint256 => uint256) positions;
}
```

### SubprotocolData
Data that is associated with a CID NFT -> subprotocol combination


```solidity
struct SubprotocolData {
    mapping(uint256 => uint256) ordered;
    uint256 primary;
    IndexedArray active;
}
```

## Enums
### AssociationType
The different types of associations between CID NFTs and subprotocol NFTs


```solidity
enum AssociationType {
    ORDERED,
    PRIMARY,
    ACTIVE
}
```

