// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ProfilePicture} from "../ProfilePicture.sol";
import {MockCidNFT} from "./mocks/MockCidNFT.sol";
import {ICidNFT} from "../../interface/ICidNFT.sol";
import {ProfilePicture} from "../ProfilePicture.sol";
import {MockERC721} from "./mocks/MockERC721.sol";

contract ProfilePictureTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;

    address payable[] internal users;

    MockCidNFT mockCidNFT;
    MockERC721 mockERC721;
    ProfilePicture pfp;

    address owner;
    address user1;
    address user2;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(10);

        owner = users[1];
        user1 = users[2];
        user2 = users[3];

        vm.startPrank(owner);
        mockCidNFT = MockCidNFT(new MockCidNFT());
        mockERC721 = MockERC721(new MockERC721());

        pfp = ProfilePicture(
            new ProfilePicture(address(mockCidNFT), "SubprotocolName")
        );
        vm.stopPrank();
    }

    function testCannotMintNFTNotOwnedByCaller() public {
        uint256 nftId = 1;

        // mint nft id 1 to user 1
        vm.prank(user1);
        mockERC721.mint(user1, nftId);

        // nft id 1 is not owned by user 2 - so should revert
        vm.expectRevert(
            abi.encodeWithSelector(
                ProfilePicture.PFPNotOwnedByCaller.selector,
                user2,
                mockERC721,
                nftId
            )
        );
        
        vm.prank(user2);
        pfp.mint(address(mockERC721), nftId);
    }


        function testMintNFTOwnedByCaller() public {
        uint256 nftId = 2;

        assertEq(pfp.numMinted(), 0);

        vm.startPrank(user1);
        mockERC721.mint(user1, nftId);


        pfp.mint(address(mockERC721), nftId);
        // num minted should increment to 1
        assertEq(pfp.numMinted(), 1);

        // mock return value for getPrimaryCIDNFT() and getAddress()
        mockCidNFT.mockReturnPrimaryCIDNFT(123);
        mockCidNFT.addressRegistry().mockReturnAddress(user1);

        // make sure called with correct parameters
        mockCidNFT.setExpectedPfpId(1);
        mockCidNFT.addressRegistry().setExpectedCidNFTID(123);
        (address nftContract, uint256 nftID) = pfp.getPFP(1);

        // assert pictureData values
        assertEq(nftContract, address(mockERC721));
        assertEq(nftID, nftId);
    }

    function testGetPFPWithNotMintedTokenID() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ProfilePicture.TokenNotMinted.selector,
                1000
            )
        );
        pfp.getPFP(1000);
    }

    function testPFPNoLongerOwnedByOriginalOwner() public {
        uint256 nftId = 123;

        // mint a pfp NFT with user1
        vm.startPrank(user1);
        mockERC721.mint(user1, nftId);
        pfp.mint(address(mockERC721), nftId);

        uint256 tokenId = 1;
        assertEq(pfp.numMinted(), tokenId);

        // mock return 0
        mockCidNFT.mockReturnPrimaryCIDNFT(0);

        // should revert since getPrimaryCIDNFT() is 0
        vm.expectRevert(
            abi.encodeWithSelector(
                ProfilePicture.PFPNoLongerOwnedByOriginalOwner.selector,
                tokenId
            )
        );
        pfp.tokenURI(tokenId);

        // mock cidNFTID to non-zero
        mockCidNFT.mockReturnPrimaryCIDNFT(1);
        // mock getAddress() to return user2. user2 is not the owner of the nft
        mockCidNFT.addressRegistry().mockReturnAddress(user2);

        // should revert since user2 is not the owner of nftId
        vm.expectRevert(
            abi.encodeWithSelector(
                ProfilePicture.PFPNoLongerOwnedByOriginalOwner.selector,
                tokenId
            )
        );
        pfp.tokenURI(tokenId);
    }

    function testPFPAssociatedWithNoCIDNFT() public {
        // Comment: Should return address(0) for nftContract
        uint256 nftId = 1;

        vm.startPrank(user1);
        mockERC721.mint(user1, nftId);
        pfp.mint(address(mockERC721), nftId);

        // mock return 0
        mockCidNFT.mockReturnPrimaryCIDNFT(0);

        (address nftContract, uint256 nftID) = pfp.getPFP(1);

        assertEq(nftContract, address(0));
        assertEq(nftID, 0);
    }

    function testNFTTransferredAfterwards() public {
        uint256 nftId = 1;

        vm.startPrank(user1);
        mockERC721.mint(user1, nftId);
        pfp.mint(address(mockERC721), nftId);

        // transfer nft from user1 to user2
        mockERC721.transferFrom(user1, user2, nftId);

        mockCidNFT.mockReturnPrimaryCIDNFT(1);
        mockCidNFT.addressRegistry().mockReturnAddress(user1);
        // since user1 no longer owns nft, nftContract should be address(0)
        (address nftContract, uint256 nftID) = pfp.getPFP(1);

        assertEq(nftContract, address(0));
        assertEq(nftID, 0);
    }

    function testTokenURINFTOwnedByOwnerOfCIDNFT() public {
        uint256 nftId = 123;

        // mint a pfp NFT with user1
        vm.startPrank(user1);
        mockERC721.mint(user1, nftId);
        pfp.mint(address(mockERC721), nftId);

        // mock return values
        mockCidNFT.mockReturnPrimaryCIDNFT(4);
        mockCidNFT.addressRegistry().mockReturnAddress(user1);
        // should return tokenURI of mockERC721
        assertEq(pfp.tokenURI(1), "abc");
    }
}
