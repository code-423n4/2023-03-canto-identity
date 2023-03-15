# AddressRegistryTest
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/test/AddressRegistry.t.sol)

**Inherits:**
DSTest


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


### addressRegistry

```solidity
AddressRegistry internal addressRegistry;
```


### cidNFT

```solidity
CidNFT cidNFT;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testRegisterNFTCallerNotOwner


```solidity
function testRegisterNFTCallerNotOwner() public;
```

### testRegisterNFTCallerIsOwner


```solidity
function testRegisterNFTCallerIsOwner() public;
```

### testOwnerOverwriteRegisteredCID


```solidity
function testOwnerOverwriteRegisteredCID() public;
```

### testRemoveWithoutRegister


```solidity
function testRemoveWithoutRegister() public;
```

### testRemovePriorRegistration


```solidity
function testRemovePriorRegistration() public;
```

### testRemoveSecondTime


```solidity
function testRemoveSecondTime() public;
```

