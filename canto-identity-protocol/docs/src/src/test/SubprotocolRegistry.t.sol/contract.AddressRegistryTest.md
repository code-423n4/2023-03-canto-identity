# AddressRegistryTest
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/test/SubprotocolRegistry.t.sol)

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


### subprotocolRegistry

```solidity
SubprotocolRegistry subprotocolRegistry;
```


### token

```solidity
MockToken token;
```


### feeWallet

```solidity
address feeWallet;
```


### user1

```solidity
address user1;
```


### user2

```solidity
address user2;
```


### feeAmount

```solidity
uint256 feeAmount;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testRegisterDifferentAssociation


```solidity
function testRegisterDifferentAssociation() public;
```

### testRegisterExistedProtocol


```solidity
function testRegisterExistedProtocol() public;
```

### testRegisterNotSubprotocolCompliantNFT


```solidity
function testRegisterNotSubprotocolCompliantNFT() public;
```

### testReturnedDataMatchSubprotocol


```solidity
function testReturnedDataMatchSubprotocol() public;
```

### testCannotRegisterWithoutTypeSpecified


```solidity
function testCannotRegisterWithoutTypeSpecified() public;
```

