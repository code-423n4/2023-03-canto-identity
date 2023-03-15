# Canto Identity Protocol (CID)

Canto Identity Protocol provides identity NFTs that associate different subprotocol NFTs with one CID NFT, which in turn is associated with a person / address. The core protocol consists of three parts:

## CID NFT
Everyone can mint a CID NFT by using the `mint` function. Then, subprotocol NFTs can be associated with this NFT using the `add` function. Depending on how the subprotocol was configured when it was added to the registry, the association of the CID NFT with the subprotocol NFT looks different:
- Ordered: In this association type, a mapping from integers (keys) to subprotocol NFTs is associated with a CID NFT / subprotocol.
- Primary: Primary means that there is one (or zero) values that are associated with a CID NFT / subprotocol combination.
- Active: In this case, a list of subprotocol NFTs can be associated with one CID NFT for the given subprotocol.
`remove` is used to remove an association again.

## Subprotocol Registry
The subprotocol registry is used to register new subprotocols. Every subprotocol is identified by a unique name. When adding it, the owner needs to define the allowed association types (see above) and if adding an NFT should cost a fee.

## Address Registry
The address registry allows user to associate their address with a CID NFT. Therefore, on-chain or off-chain applications can check this registry to get the CID NFT ID that is associated with a user.

## Subprotocols
To describe, common interface, liveness checks, ...

# Testing

```
forge test
```

## Checking Coverage

```
forge coverage
```