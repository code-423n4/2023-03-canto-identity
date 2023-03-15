# Canto Bio Protocol
Canto Bio Protocol is a subprotocol for the Canto Identity Protocol that enables users to link a biography to their identity.

## Minting
Any user can mint a Bio NFT by calling `Bio.mint` and passing his biography. It needs to be shorter than 200 characters.

## `tokenURI`
An SVG image that displays the biography is dynamically created for every minted NFT. A line break is automatically inserted in the generated SVG.