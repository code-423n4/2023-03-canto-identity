# CidNFTTest
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/test/CidNFT.t.sol)

**Inherits:**
DSTest, ERC721TokenReceiver


## State Variables
### vm

```solidity
Vm internal immutable vm = Vm(HEVM_ADDRESS);
```


### utils

```solidity
Utilities internal utils;
```


### users

```solidity
address payable[] internal users;
```


### feeWallet

```solidity
address internal feeWallet;
```


### user1

```solidity
address internal user1;
```


### user2

```solidity
address internal user2;
```


### BASE_URI

```solidity
string internal constant BASE_URI = "tbd://base_uri/";
```


### note

```solidity
MockToken internal note;
```


### subprotocolRegistry

```solidity
SubprotocolRegistry internal subprotocolRegistry;
```


### sub1

```solidity
SubprotocolNFT internal sub1;
```


### sub2

```solidity
SubprotocolNFT internal sub2;
```


### cidNFT

```solidity
CidNFT internal cidNFT;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testAddID0


```solidity
function testAddID0() public;
```

### testAddNonExistingSubprotocol


```solidity
function testAddNonExistingSubprotocol() public;
```

### testRemoveNonExistingSubprotocol


```solidity
function testRemoveNonExistingSubprotocol() public;
```

### testCannotRemoveNonExistingEntry


```solidity
function testCannotRemoveNonExistingEntry() public;
```

### testCannotRemoveWhenOrderedOrActiveNotSet


```solidity
function testCannotRemoveWhenOrderedOrActiveNotSet() public;
```

### testMintWithoutAddList


```solidity
function testMintWithoutAddList() public;
```

### testMintWithSingleAddList


```solidity
function testMintWithSingleAddList() public;
```

### testMintWithMultiAddItems


```solidity
function testMintWithMultiAddItems() public;
```

### testMintWithMultiAddItemsAndRevert


```solidity
function testMintWithMultiAddItemsAndRevert() public;
```

### prepareAddOne


```solidity
function prepareAddOne(address cidOwner, address subOwner)
    internal
    returns (uint256 tokenId, uint256 sub1Id, uint256 key1);
```

### testAddRemoveByOwner


```solidity
function testAddRemoveByOwner() public;
```

### testAddDuplicate


```solidity
function testAddDuplicate() public;
```

### testAddRemoveByApprovedAccount


```solidity
function testAddRemoveByApprovedAccount() public;
```

### testAddRemoveByApprovedAllAccount


```solidity
function testAddRemoveByApprovedAllAccount() public;
```

### testAddRemoveByUnauthorizedAccount


```solidity
function testAddRemoveByUnauthorizedAccount() public;
```

### tryAddType


```solidity
function tryAddType(bool valid, string memory subName, CidNFT.AssociationType aType) internal;
```

### testAddUnsupportedAssociationType


```solidity
function testAddUnsupportedAssociationType() public;
```

### testAddRemoveOrderedType


```solidity
function testAddRemoveOrderedType() public;
```

### testAddRemovePrimaryType


```solidity
function testAddRemovePrimaryType() public;
```

### testAddRemoveActiveType


```solidity
function testAddRemoveActiveType() public;
```

### addMultipleActiveTypeValues


```solidity
function addMultipleActiveTypeValues(address user, uint256 count)
    internal
    returns (uint256 tokenId, uint256[] memory subIds);
```

### testAddMultipleActiveTypeValues


```solidity
function testAddMultipleActiveTypeValues() public;
```

### checkActiveValues


```solidity
function checkActiveValues(uint256 tokenId, string memory subName, uint256[] memory expectedIds, uint256 count)
    internal;
```

### testRemoveActiveValues


```solidity
function testRemoveActiveValues() public;
```

### testOverwritingOrdered


```solidity
function testOverwritingOrdered() public;
```

### testOverWritingPrimary


```solidity
function testOverWritingPrimary() public;
```

### testAddWithNotEnoughFee


```solidity
function testAddWithNotEnoughFee() public;
```

### testAddWithFee


```solidity
function testAddWithFee() public;
```

### testTokenURI


```solidity
function testTokenURI() public;
```

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

### OrderedDataRemoved

```solidity
event OrderedDataRemoved(
    uint256 indexed cidNFTID, string indexed subprotocolName, uint256 indexed key, uint256 subprotocolNFTID
);
```

### ActiveDataAdded

```solidity
event ActiveDataAdded(
    uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID, uint256 arrayIndex
);
```

