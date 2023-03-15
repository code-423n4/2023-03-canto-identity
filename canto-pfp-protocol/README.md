# Canto Profile Pictures Protocol
Canto Profile Pictures Protocol is a subprotocol for the Canto Identity Protocol that enables users to link profile pictures (arbitrary NFTs) to their identity.

## Minting
Any user can mint a PFP NFT by calling `ProfilePicture.mint` and passing the address and the ID of the profile picture NFT that should be referenced with this PFP NFT. The user that calls this function has to own the referenced NFT.

## Ownership check
The PFP subprotocol is integrated with CID for ownership checks. Whenever `tokenURI` is called, it is checked with which CID NFT the PFP is associated and with which address this CID NFT is registered (in the address registry). If this address does not own the referenced NFT (e.g., because it was sold) or the PFP NFT is not associated with any CID NFT, the `tokenURI` call reverts. Otherwise, it is forwarded to the referenced NFT.

Note that this ownership check can also be performed explicitly by calling `getPFP(uint256 pfpID)`, which returns the address & id of the referenced NFT, if it is owned by the user that is associated with the CID NFT. If not, `address(0)` is returned.