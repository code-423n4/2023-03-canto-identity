# Utilities
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/test/utils/Utilities.sol)

**Inherits:**
DSTest


## State Variables
### vm

```solidity
Vm internal immutable vm = Vm(HEVM_ADDRESS);
```


### nextUser

```solidity
bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));
```


## Functions
### getNextUserAddress


```solidity
function getNextUserAddress() external returns (address payable);
```

### createUsers


```solidity
function createUsers(uint256 userNum) external returns (address payable[] memory);
```

### mineBlocks


```solidity
function mineBlocks(uint256 numBlocks) external;
```

