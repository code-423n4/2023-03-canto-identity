// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/Bio.sol";

contract BioTest is Test {
    Bio public bio;
    address public alice;

    event BioAdded(address indexed minter, uint256 indexed nftID, string indexed bio);

    error TokenNotMinted(uint256 tokenID);
    error InvalidBioLength(uint256 length);

    function setUp() public {
        bio = new Bio();
        alice = address(1);
    }

    function slice(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex < endIndex, "Invalid indices");
        require(endIndex <= strBytes.length, "End index out of range");

        bytes memory sliced = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            sliced[i - startIndex] = strBytes[i];
        }
        return string(sliced);
    }

    function countSubStr(string memory str, string memory substr) public pure returns (uint256) {
        uint256 count = 0;
        uint256 len = bytes(str).length;
        uint256 sublen = bytes(substr).length;
        if (len < sublen) return 0;
        for (uint256 i = 0; i <= len - sublen; i++) {
            bool found = true;
            for (uint256 j = 0; j < sublen; j++) {
                if (bytes(str)[i + j] != bytes(substr)[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                count++;
            }
        }
        return count;
    }
    
   function testMint() public {
        string memory _bio = "TEST BIO";
        uint256 prevNnumMinted = bio.numMinted();
        uint256 nnumMinted = prevNnumMinted + 1;

        vm.expectEmit(true, true, true, true);
        emit BioAdded(alice, nnumMinted, _bio);

        vm.prank(alice);
        bio.mint(_bio);

        assertEq(bio.numMinted(), nnumMinted, "Wrong tokenId");
        assertEq(bio.bio(nnumMinted), _bio, "Wrong _bio");
        assertEq(bio.ownerOf(nnumMinted), alice, "NFT not minted");
    }

    function testShortString(string memory text) public {
        uint256 len = bytes(text).length;
        vm.assume(len > 0 && len < 40);
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        assertEq(countSubStr(svg, "<tspan ") - countSubStr(text, "<tspan "), 1);
    }

    function testLongString(string memory text) public {
        uint256 len = bytes(text).length;
        vm.assume(len > 40 && len <= 200);
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        assertEq(countSubStr(svg, "<tspan ") - countSubStr(text, "<tspan "), (len - 1) / 40 + 1);
    }

    function testEmojiAtBoundaries() public {
        string memory text = unicode"012345678901234567890123456789012345678👨‍👩‍👧‍👧";
        uint256 len = bytes(text).length;
        assertEq(len, 64);
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        // make sure the svg still contain the complete emoji
        assertEq(countSubStr(svg, unicode"👨‍👩‍👧‍👧"), 1);
    }

    function testEmojiAtBoundaries2() public {
        string memory text = unicode"012345678901234567890123456789012345678👍🏿";
        uint256 len = bytes(text).length;
        assertEq(len, 47);
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        // make sure the svg still contain the complete emoji
        assertEq(countSubStr(svg, unicode"👍🏿"), 1);
    }

    function testRevertOver200() public {
        string memory text =
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        uint256 len = bytes(text).length;
        assertGt(len, 200);
        vm.expectRevert(abi.encodeWithSelector(InvalidBioLength.selector, len));
        bio.mint(text);
    }

    function testRevertLen0() public {
        string memory text = "";
        uint256 len = bytes(text).length;
        assertEq(len, 0);
        vm.expectRevert(abi.encodeWithSelector(InvalidBioLength.selector, len));
        bio.mint(text);
    }
}