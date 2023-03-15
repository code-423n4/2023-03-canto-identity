# IntegrationTest
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/test/IntegrationTest.t.sol)

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


### user3

```solidity
address internal user3;
```


### alice

```solidity
address internal alice;
```


### bob

```solidity
address internal bob;
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


### addressRegistry

```solidity
AddressRegistry internal addressRegistry;
```


### sub1

```solidity
SubprotocolNFT internal sub1;
```


### sub2

```solidity
SubprotocolNFT internal sub2;
```


### sub3

```solidity
SubprotocolNFT internal sub3;
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

### testIntegrationCaseOne


```solidity
function testIntegrationCaseOne() public;
```

### testIntegrationCaseTwo


```solidity
function testIntegrationCaseTwo() public;
```

