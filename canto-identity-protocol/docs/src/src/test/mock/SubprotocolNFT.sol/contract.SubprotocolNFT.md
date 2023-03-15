# SubprotocolNFT
[Git Source](https://github.com/mkt-market/canto-identity-protocol/blob/1a16b30b450fe389c483f47dc1621b0d0fe1bd63/src/test/mock/SubprotocolNFT.sol)

**Inherits:**
[CidSubprotocolNFT](/src/CidSubprotocolNFT.sol/contract.CidSubprotocolNFT.md)


## Functions
### constructor


```solidity
constructor() ERC721("MockNFT", "MNFT");
```

### mint


```solidity
function mint(address to, uint256 tokenId) public;
```

### isActive


```solidity
function isActive(uint256) public pure override returns (bool active);
```

### tokenURI


```solidity
function tokenURI(uint256) public pure override returns (string memory);
```

