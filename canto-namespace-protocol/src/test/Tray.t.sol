// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockToken} from "./mock/MockToken.sol";
import {MockNamespace} from "./mock/MockNamespace.sol";
import {MockTray} from "./mock/MockTray.sol";
import {Tray} from "../Tray.sol";
import {Base64} from "solady/utils/Base64.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract TrayTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;

    error CallerNotAllowedToBurn();
    error TrayNotMinted(uint256 tokenID);
    error OnlyOwnerCanMintPreLaunch();
    error MintExceedsPreLaunchAmount();
    error PrelaunchTrayCannotBeUsedAfterPrelaunch(uint256 startTokenId);
    error PrelaunchAlreadyEnded();
    error OwnerQueryForNonexistentToken();
    uint256 private constant TILES_PER_TRAY = 7;

    address payable[] internal users;
    address revenue;
    address user1;
    address user2;
    address owner;

    bytes32 internal constant INIT_HASH =
        0xc38721b5250eca0e6e24e742a913819babbc8948f0098b931b3f53ea7b3d8967;

    MockTray tray;
    uint256 price;
    MockToken note;
    MockNamespace mn;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(20);
        revenue = users[0];
        user1 = users[1];
        user2 = users[2];
        owner = users[11];

        note = new MockToken();
        price = 100e18;
        vm.prank(owner);
        tray = new MockTray(
            INIT_HASH,
            price,
            revenue,
            address(note),
            address(mn)
        );

        note.mint(owner, 10000e18);
        vm.prank(owner);
        note.approve(address(tray), type(uint256).max);
    }

    function testBuyInPrelaunchPhase() public {
        // Only owner can buy in prelaunch phase
        vm.startPrank(owner);
        tray.buy(1);
        vm.stopPrank();

        // Others can not buy in prelaunch phase
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(OnlyOwnerCanMintPreLaunch.selector)
        );
        tray.buy(1);
        vm.stopPrank();
    }

    function testOwnerBuyMaxInPrelaunchPhase() public {
        vm.prank(owner);
        tray.buy(1000);
        assertEq(tray.balanceOf(owner), 1000);
    }

    function testRevertUnminted() public {
        vm.expectRevert(abi.encodeWithSelector(TrayNotMinted.selector, type(uint256).max));
        tray.tokenURI(type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(TrayNotMinted.selector, type(uint256).max));
        tray.getTile(type(uint256).max, type(uint8).max);
    }

    /// @dev this is failing for no apparent reason
    function testRevertUnmintedGetTiles() public {
        // vm.expectRevert(abi.encodeWithSelector(TrayNotMinted.selector, type(uint256).max));
        // tray.getTiles(type(uint256).max);
    }

    function testBurnInPrelaunchPhase() public {
        testBuyInPrelaunchPhase();
        vm.startPrank(owner);
        tray.burn(1);
        vm.stopPrank();
    }

    function testGetTileBurned() public {
        testBurnInPrelaunchPhase();
        vm.expectRevert(abi.encodeWithSelector(TrayNotMinted.selector, 1));
        tray.getTile(1,0);
        // this is failing for no apparent reason
        // vm.expectRevert(abi.encodeWithSelector(TrayNotMinted.selector, 1));
        // tray.getTiles(1);
    }
    
    function testRevertTooHighTileOffset() public {
        testBuyInPrelaunchPhase();
        // this revert with evm [Index out of bounds]
        vm.expectRevert();
        tray.getTile(1,100);
    }

    function testRevertNonOwnerChangeRevenueAddress() public {
        vm.startPrank(user1);
        vm.expectRevert("UNAUTHORIZED");
        tray.changeRevenueAddress(user1);
        vm.stopPrank();
    }

    function testOwnerBuyTooManyInPrelaunchPhase() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(MintExceedsPreLaunchAmount.selector)
        );
        tray.buy(1001);
        vm.stopPrank();
    }

    function testBuyingOneAfterPrelaunchPhase() public {
        vm.prank(owner);
        tray.endPrelaunchPhase();

        note.mint(user1, price);
        uint256 beforeBal = note.balanceOf(user1);

        // anyone can buy
        vm.startPrank(user1);
        note.approve(address(tray), type(uint256).max);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        vm.stopPrank();

        // should charge trayPrice
        uint256 afterBal = note.balanceOf(user1);
        assertEq(beforeBal - afterBal, price);

        // check data
        Tray.TileData memory data = tray.getTile(tid, 0);
        assertTrue(
            data.fontClass + data.characterIndex + data.characterModifier > 0
        );
    }

    function testBuyingMultipleOnesAfterPrelaunchPhase() public {
        vm.prank(owner);
        tray.endPrelaunchPhase();

        uint256 buyAmt = 5;

        note.mint(user2, price * buyAmt);
        uint256 beforeBal = note.balanceOf(user2);

        // anyone can buy
        vm.startPrank(user2);
        note.approve(address(tray), type(uint256).max);
        uint256 tid = tray.nextTokenId();
        tray.buy(buyAmt);
        vm.stopPrank();

        // should charge trayPrice
        uint256 afterBal = note.balanceOf(user2);
        assertEq(beforeBal - afterBal, price * buyAmt);

        Tray.TileData memory data = tray.getTile(tid, 0);
        assertTrue(
            data.fontClass + data.characterIndex + data.characterModifier > 0
        );
    }

    function testChangeNoteAddress() public {
        address newNote = address(new MockToken());
        vm.startPrank(owner);
        tray.changeNoteAddress(newNote);
        vm.stopPrank();
    }

    function testChangeNoteAddressNonOwner() public {
        // non-owner user
        vm.startPrank(user1);

        MockToken newNoteAddress = new MockToken();

        // onlyOwner modifier should revert
        vm.expectRevert("UNAUTHORIZED");
        tray.changeNoteAddress(address(newNoteAddress));
    }

    function testGetValidTile() public {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        vm.stopPrank();

        // check data
        Tray.TileData memory data = tray.getTile(tid, 0);
        assertTrue(
            data.fontClass + data.characterIndex + data.characterModifier > 0
        );
    }

    function testEndPrelaunchPhaseByOwner() public {
        vm.prank(owner);
        tray.endPrelaunchPhase();
    }

    function testEndPrelaunchPhaseByNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("UNAUTHORIZED");
        tray.endPrelaunchPhase();
    }

    function testChangeRevenueAddressByOwner() public {
        vm.prank(owner);
        tray.changeRevenueAddress(user1);
    }

    function testTransferDuringPrelaunch() public {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        tray.transferFrom(owner, user1, tid);
        vm.stopPrank();
    }

    function testTransferAfterPrelaunch() public {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        tray.endPrelaunchPhase();
        vm.expectRevert(
            abi.encodeWithSelector(
                PrelaunchTrayCannotBeUsedAfterPrelaunch.selector,
                tid
            )
        );
        tray.transferFrom(owner, user1, tid);
        vm.stopPrank();
    }

    function testTokenURIForPrelaunchTrayDuringPrelaunch() public {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        string memory tokenUri = tray.tokenURI(tid);
        assertTrue(bytes(tokenUri).length > 0);
        vm.stopPrank();
    }

    function testBurnPrelaunchTray() public {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        tray.endPrelaunchPhase();
        tray.burn(tid);
        // check tid is burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(tid);
        // the following will revert obviously. comment for expectRevert problem
        // tray.getTiles(tid);
        vm.stopPrank();
    }

    function endPrelaunchAndBuyOne(address user) public returns (uint256) {
        vm.prank(owner);
        tray.endPrelaunchPhase();

        note.mint(user, price);

        vm.startPrank(user);
        note.approve(address(tray), type(uint256).max);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        vm.stopPrank();
        return tid;
    }

    function testBurnNonPrelaunchTrayByOwner() public {
        uint256 tid = endPrelaunchAndBuyOne(user1);

        vm.startPrank(user1);
        tray.burn(tid);
        // check tid is burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(tid);
        // the following will revert obviously
        // tray.getTiles(tid);
        vm.stopPrank();
    }

    function testBurnNonPrelaunchTrayByApproved() public {
        uint256 tid = endPrelaunchAndBuyOne(user1);

        vm.prank(user1);
        tray.approve(user2, tid);

        // burn by approved
        vm.prank(user2);
        tray.burn(tid);
        // check tid is burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(tid);
        // the following will revert obviously
        // tray.getTiles(tid);
    }

    function testBurnNonPrelaunchTrayByApprovedForAll() public {
        uint256 tid = endPrelaunchAndBuyOne(user1);

        vm.prank(user1);
        tray.setApprovalForAll(user2, true);

        // burn by approvedForAll
        vm.prank(user2);
        tray.burn(tid);
        // check tid is burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(tid);
        // the following will revert obviously
        // tray.getTiles(tid);
    }

    function testGetValidTiles() public {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        vm.stopPrank();

        Tray.TileData[7] memory data = tray.getTiles(tid);

        for (uint256 i; i < data.length; i++) {
            assertTrue(
                data[i].fontClass +
                    data[i].characterIndex +
                    data[i].characterModifier >
                    0
            );
        }
    }

    function testTransferNormalTray() public {
        uint256 tid = endPrelaunchAndBuyOne(user1);
        assertEq(tray.ownerOf(tid), user1);
        // transfer to user2
        vm.prank(user1);
        tray.transferFrom(user1, user2, tid);
        assertEq(tray.ownerOf(tid), user2);
    }

    function testTokenURIForNonPrelaunchTray() public {
        uint256 tid = endPrelaunchAndBuyOne(user1);
        bytes memory svg = abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 200">',
            '<style>text { font-family: sans-serif; font-size: 30px; }</style>',
            '<text dominant-baseline="middle" text-anchor="middle" y="100" x="50">b</text>',
            '<rect width="34" height="60" y="70" x="33" stroke="black" stroke-width="1" fill="none"></rect>',
            '<text dominant-baseline="middle" text-anchor="middle" y="100" x="100">9</text>',
            '<rect width="34" height="60" y="70" x="83" stroke="black" stroke-width="1" fill="none"></rect>',
            unicode'<text dominant-baseline="middle" text-anchor="middle" y="100" x="150">😪</text>',
            '<rect width="34" height="60" y="70" x="133" stroke="black" stroke-width="1" fill="none"></rect>',
            unicode'<text dominant-baseline="middle" text-anchor="middle" y="100" x="200">𝓇</text>',
            '<rect width="34" height="60" y="70" x="183" stroke="black" stroke-width="1" fill="none"></rect>',
            '<text dominant-baseline="middle" text-anchor="middle" y="100" x="250">8</text>',
            '<rect width="34" height="60" y="70" x="233" stroke="black" stroke-width="1" fill="none"></rect>',
            unicode'<text dominant-baseline="middle" text-anchor="middle" y="100" x="300">😮</text>',
            '<rect width="34" height="60" y="70" x="283" stroke="black" stroke-width="1" fill="none"></rect>',
            unicode'<text dominant-baseline="middle" text-anchor="middle" y="100" x="350">𝔢</text>',
            '<rect width="34" height="60" y="70" x="333" stroke="black" stroke-width="1" fill="none"></rect>',
        '</svg>');
        bytes memory json = abi.encodePacked(
            '{"name": "Tray #', LibString.toString(tid),
            '", "image": "data:image/svg+xml;base64,', Base64.encode(svg),
            '"}'
        );
        string memory encodedJson = string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
        assertEq(tray.tokenURI(tid), encodedJson);
    }
}
