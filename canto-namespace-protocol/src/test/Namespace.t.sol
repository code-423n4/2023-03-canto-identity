// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockToken} from "./mock/MockToken.sol";
import {MockTray} from "./mock/MockTray.sol";
import {Namespace} from "../Namespace.sol";
import {Tray} from "../Tray.sol";

contract NamespaceTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    Utilities internal utils;

    error InvalidNumberOfCharacters(uint256 numCharacters);
    error PrelaunchTrayCannotBeUsedAfterPrelaunch(uint256 startTokenId);
    error FusingDuplicateCharactersNotAllowed();
    error TokenNotMinted(uint256 tokenID);
    error OwnerQueryForNonexistentToken();
    event RevenueAddressUpdated(
        address indexed oldRevenueAddress,
        address indexed newRevenueAddress
    );
    error EmojiDoesNotSupportSkinToneModifier(uint16 emojiIndex);

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
    Namespace ns;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(20);
        revenue = users[0];
        user1 = users[1];
        user2 = users[2];
        owner = users[11];

        note = new MockToken();
        price = 100e18;
        address predicatedTrayAddr = 0x974B69642e9c55f93380380AA45DFA2c811F163E;

        vm.prank(owner);
        ns = new Namespace(predicatedTrayAddr, address(note), revenue);

        vm.prank(owner);
        tray = new MockTray(
            INIT_HASH,
            price,
            revenue,
            address(note),
            address(ns)
        );
        assertEq(address(tray), predicatedTrayAddr);

        note.mint(owner, 10000e18);
        vm.prank(owner);
        note.approve(address(ns), type(uint256).max);
    }

    function testFusingWith0Characters() public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidNumberOfCharacters.selector, 0)
        );
        ns.fuse(new Namespace.CharacterData[](0));
    }

    function testFusingWithMoreThan13Characters() public {
        vm.expectRevert(
            abi.encodeWithSelector(InvalidNumberOfCharacters.selector, 14)
        );
        ns.fuse(new Namespace.CharacterData[](14));
    }

    function buyOnePrelaunch(bool endPrelaunch) internal returns (uint256) {
        vm.startPrank(owner);
        uint256 tid = tray.nextTokenId();
        tray.buy(1);
        if (endPrelaunch) {
            tray.endPrelaunchPhase();
        }
        vm.stopPrank();
        return tid;
    }

    function testFusingWithPrelaunchTrayAfterPrelaunch() public {
        uint256 tid = buyOnePrelaunch(true);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(tid, 0, 0);
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                PrelaunchTrayCannotBeUsedAfterPrelaunch.selector,
                tid
            )
        );
        ns.fuse(list);
    }

    function testFusingWithDuplicateTiles() public {
        uint256 tid = buyOnePrelaunch(false);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            2
        );
        list[0] = Namespace.CharacterData(tid, 0, 0);
        list[1] = Namespace.CharacterData(tid, 0, 0);
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(FusingDuplicateCharactersNotAllowed.selector)
        );
        ns.fuse(list);
    }

    function testChangeNoteAddressByOwner() public {
        address newNote = address(new MockToken());
        vm.prank(owner);
        ns.changeNoteAddress(newNote);
        assertEq(address(ns.note()), newNote);
    }

    function testChangeNoteAddressByNonOwner() public {
        address newNote = address(new MockToken());
        vm.prank(user1);
        vm.expectRevert("UNAUTHORIZED");
        ns.changeNoteAddress(newNote);
        assertEq(address(ns.note()), address(note));
    }

    function testChangeRevenueAddressByOwner() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit RevenueAddressUpdated(revenue, user2);
        ns.changeRevenueAddress(user2);
    }

    function testChangeRevenueAddressByNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("UNAUTHORIZED");
        ns.changeRevenueAddress(user2);
    }

    function testTokenURIOfNonMintedToken() public {
        uint256 id = 123;
        vm.expectRevert(abi.encodeWithSelector(TokenNotMinted.selector, id));
        ns.tokenURI(id);
    }

    function testTokenURIOfBurnedToken() public {
        uint256 trayId = buyOnePrelaunch(false);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(owner);
        ns.fuse(list);
        uint256 id = ns.nextNamespaceIDToMint();
        ns.burn(id);
        vm.expectRevert(abi.encodeWithSelector(TokenNotMinted.selector, id));
        ns.tokenURI(id);
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

    function calcFusingCosts(
        uint256 numCharacters
    ) internal pure returns (uint256) {
        return 2 ** (13 - numCharacters) * 1e18;
    }

    function testFusingAsOwnerOfTray() public {
        address user = user1;
        note.mint(user, 10000e18);
        uint256 trayId = endPrelaunchAndBuyOne(user);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        uint256 beforeBalance = note.balanceOf(user);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(user);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(trayId);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(1));

        vm.stopPrank();
    }

    function testBurnAsOwner() public {
        address user = user1;
        note.mint(user, 10000e18);
        uint256 trayId = endPrelaunchAndBuyOne(user);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        ns.fuse(list);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);

        // burn as owner
        ns.burn(id);

        // tokenToName is cleared
        name = ns.tokenToName(id);
        assertEq(bytes(name).length, 0);
        // nameToToken is cleared
        assertEq(ns.nameToToken(name), 0);
        vm.stopPrank();
    }

    function testFusingAsApprovedOfTray() public {
        uint256 trayId = endPrelaunchAndBuyOne(user2);
        vm.prank(user2);

        address user = user1;
        // approve to user
        tray.approve(user, trayId);

        note.mint(user, 10000e18);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        uint256 beforeBalance = note.balanceOf(user);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(user);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(trayId);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(1));

        vm.stopPrank();
    }

    function testBurnAsApprovedForAllOfOwner() public {
        note.mint(user1, 10000e18);
        uint256 trayId = endPrelaunchAndBuyOne(user1);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(user1);
        note.approve(address(ns), type(uint256).max);
        ns.fuse(list);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        vm.stopPrank();

        // setApprovalForAll
        vm.prank(user1);
        ns.setApprovalForAll(user2, true);

        // burn as approvedForAll (of user 1)
        vm.prank(user2);
        ns.burn(id);

        // id is burned
        vm.expectRevert("NOT_MINTED");
        ns.ownerOf(id);
        // tokenToName is cleared
        name = ns.tokenToName(id);
        assertEq(bytes(name).length, 0);
        // nameToToken is cleared
        assertEq(ns.nameToToken(name), 0);
    }

    function testFusingWithOneTrayAndOneTile() public {
        address user = user1;
        note.mint(user, 10000e18);
        uint256 trayId = endPrelaunchAndBuyOne(user);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 1, 0);
        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        uint256 beforeBalance = note.balanceOf(user);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(user);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(trayId);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(1));

        vm.stopPrank();
    }

    function testFusingWithOneTrayAndMultiTiles() public {
        address user = user1;
        note.mint(user, 10000e18);
        uint256 trayId = endPrelaunchAndBuyOne(user);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            3
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        list[1] = Namespace.CharacterData(trayId, 5, 0);
        list[2] = Namespace.CharacterData(trayId, 2, 0);

        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        uint256 beforeBalance = note.balanceOf(user);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(user);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, list.length);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(trayId);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(list.length));

        vm.stopPrank();
    }

    function testFusingAsApprovedForAllOfTrayOwner() public {
        uint256 trayId = endPrelaunchAndBuyOne(user2);
        vm.prank(user2);

        address user = user1;
        // setApprovalForAll
        tray.setApprovalForAll(user, true);

        note.mint(user, 10000e18);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        uint256 beforeBalance = note.balanceOf(user);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(user);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(trayId);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(1));

        vm.stopPrank();
    }

    function buyTray(
        address user,
        uint256 amount
    ) public returns (uint256[] memory trayIds) {
        note.mint(user, amount * price);
        vm.startPrank(user);
        note.approve(address(tray), type(uint256).max);
        uint256 fromId = tray.nextTokenId();
        tray.buy(amount);
        vm.stopPrank();
        // return ids
        trayIds = new uint256[](amount);
        for (uint256 i; i < amount; ++i) {
            trayIds[i] = fromId + i;
        }
    }

    function testFusingWithMuTrayAndMultiTiles() public {
        address user = user1;
        note.mint(user, 10000e18);
        endPrelaunchAndBuyOne(user);

        uint256[] memory trayIds = buyTray(user, 3);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            5
        );
        list[0] = Namespace.CharacterData(trayIds[0], 0, 0);
        list[1] = Namespace.CharacterData(trayIds[1], 0, 0);
        list[2] = Namespace.CharacterData(trayIds[2], 3, 0);
        list[3] = Namespace.CharacterData(trayIds[2], 2, 0);
        list[4] = Namespace.CharacterData(trayIds[1], 5, 0);

        vm.startPrank(user);
        note.approve(address(ns), type(uint256).max);
        uint256 beforeBalance = note.balanceOf(user);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(user);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        for (uint256 i; i < trayIds.length; ++i) {
            vm.expectRevert(
                abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
            );
            tray.ownerOf(trayIds[i]);
        }
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(list.length));
        vm.stopPrank();
    }

    function buildCharacters(
        uint256 trayId
    ) internal pure returns (Namespace.CharacterData[] memory list) {
        list = new Namespace.CharacterData[](7);
        for (uint8 i; i < 7; i++) {
            list[i] = Namespace.CharacterData(trayId, i, 0);
        }
    }

    function testComplexScenario() public {
        // prepare users
        address Alice = users[1];
        address Bob = users[2];
        address Charlie = users[3];
        for (uint256 i = 1; i <= 3; ++i) {
            note.mint(users[i], 1e6 * 1e18);
            vm.prank(users[i]);
            note.approve(address(ns), type(uint256).max);
            note.approve(address(tray), type(uint256).max);
        }

        // == during prelaunch ==
        // owner mint 100 trays
        vm.prank(owner);
        tray.buy(100);
        assertEq(tray.balanceOf(owner), 100);

        // owner distributes tray 11-19 to Alice
        for (uint256 trayId = 11; trayId <= 19; ++trayId) {
            vm.prank(owner);
            tray.transferFrom(owner, Alice, trayId);
            assertEq(tray.ownerOf(trayId), Alice);
        }
        // owner distributes tray 21-29 to Bob
        for (uint256 trayId = 21; trayId <= 29; ++trayId) {
            vm.prank(owner);
            tray.transferFrom(owner, Bob, trayId);
            assertEq(tray.ownerOf(trayId), Bob);
        }

        // Alice mints 2 namespace NFTs
        uint256[] memory aliceMintIds = new uint256[](2);
        for (uint256 i; i < aliceMintIds.length; i++) {
            vm.prank(Alice);
            ns.fuse(buildCharacters(11 + i));
            uint256 id = ns.nextNamespaceIDToMint();
            // check mint result
            assertEq(ns.ownerOf(id), Alice);
            aliceMintIds[i] = id;
        }
        // Bob mints 3 namespace NFTs
        for (uint256 i; i < 3; i++) {
            vm.prank(Bob);
            ns.fuse(buildCharacters(21 + i));
            uint256 id = ns.nextNamespaceIDToMint();
            // check mint result
            assertEq(ns.ownerOf(id), Bob);
        }

        // end prelaunch
        vm.prank(owner);
        tray.endPrelaunchPhase();

        // == after prelaunch ==
        // Alice transfers 1 namespace to Charlie
        vm.prank(Alice);
        ns.transferFrom(Alice, Charlie, aliceMintIds[0]);
        assertEq(ns.ownerOf(aliceMintIds[0]), Charlie);

        // Charlie buys 10 trays
        uint256[] memory trayIds = buyTray(Charlie, 10);
        assertEq(tray.balanceOf(Charlie), 10);

        // Charlie mints another namespace NFT
        vm.prank(Charlie);
        ns.fuse(buildCharacters(trayIds[0]));
        uint256 newId = ns.nextNamespaceIDToMint();
        assertEq(ns.ownerOf(newId), Charlie);
    }

    function testFusingDuringPrelaunch() public {
        uint256 trayId = buyOnePrelaunch(false);
        vm.startPrank(owner);

        Namespace.CharacterData[] memory list = buildCharacters(trayId);
        uint256 beforeBalance = note.balanceOf(owner);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(owner);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(trayId);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(list.length));

        vm.stopPrank();
    }

    function testBurnAsApproved() public {
        note.mint(user1, 10000e18);
        uint256 trayId = endPrelaunchAndBuyOne(user1);
        vm.startPrank(user1);
        note.approve(address(ns), type(uint256).max);
        ns.fuse(buildCharacters(trayId));
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        vm.stopPrank();

        // approve user2
        vm.prank(user1);
        ns.approve(user2, id);

        // burn as approved
        vm.prank(user2);
        ns.burn(id);

        // id is burned
        vm.expectRevert("NOT_MINTED");
        ns.ownerOf(id);
        // tokenToName is cleared
        name = ns.tokenToName(id);
        assertEq(bytes(name).length, 0);
        // nameToToken is cleared
        assertEq(ns.nameToToken(name), 0);
    }

    function testTokenURIProperlyRendered() public {
        uint256 trayId = buyOnePrelaunch(false);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );
        list[0] = Namespace.CharacterData(trayId, 0, 0);
        vm.startPrank(owner);

        ns.fuse(list);
        
        string memory tokenURIData = ns.tokenURI(1);
        console.logString(tokenURIData);

    }

    function testFuseCharacterWithSkinToneModifier() public {
        uint256 trayId = buyOnePrelaunch(false);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );

        uint8 tileOffset = 1;
        uint8 skinToneModifier = 4;

        list[0] = Namespace.CharacterData(trayId, tileOffset, skinToneModifier);
        vm.startPrank(owner);

        vm.expectRevert(
            Namespace.CannotFuseCharacterWithSkinTone.selector
        );
        ns.fuse(list);
    }

    function testFuseEmojiDoesNotSupportSkinTone() public {
        uint256 trayId = buyOnePrelaunch(false);
        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );

        uint8 tileOffset = 2;
        uint8 skinToneModifier = 4;

        list[0] = Namespace.CharacterData(trayId, tileOffset, skinToneModifier);
        vm.startPrank(owner);

        Tray.TileData memory tileData = tray.getTile(trayId, tileOffset);

        require(
            tileData.fontClass == 0, 
            "fontClass should be 0, which is emoji font class"
        );

        // character 161 is 😪, expecting revert
        vm.expectRevert(
            abi.encodeWithSelector(
                EmojiDoesNotSupportSkinToneModifier.selector, 
                161
            )
        );

        ns.fuse(list);

    }

    function testSelectTrayIdToFuseSupportSkinTone() public {

        for(uint256 i = 0; i < 100; i++) {

            vm.startPrank(owner);
            uint256 tid = tray.nextTokenId();
            tray.buy(1);
            vm.stopPrank();

            uint8 tileOffset = 0;
            uint8 skinToneModifier = 4;

            Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
                1
            );

            list[0] = Namespace.CharacterData(tid, tileOffset, skinToneModifier);
            vm.startPrank(owner);

            Tray.TileData memory tileData = tray.getTile(tid, tileOffset);

            // selected tray id 4 with tileOffset 0
            // 💃🏾 is used to fuse NFT, the emoji 💃🏾 does support skin modifier
            if(tileData.fontClass == 0) {
                try ns.fuse(list) {
                    console.log("tray id (need to plus because i starts at 0)");
                    console.log(i);
                    console.log("fuse with an emoji with skin tone modifier works");
                    string memory tokenURIData = ns.tokenURI(1);
                    console.logString(tokenURIData);
                    break;
                } catch (bytes memory reason) {
                  console.logBytes(reason);
                }
            }
            vm.stopPrank();
            
        }

    }

    function testFuseWithEmojiSupportToneModifier() public {

        vm.startPrank(owner);

        tray.buy(1);
        tray.buy(1);
        tray.buy(1);
        tray.buy(1);
        tray.buy(1);
    
        uint256 tid = 4;

        uint8 tileOffset = 0;
        uint8 skinToneModifier = 4;

        // fuse with emoji 💃🏾, which support skin modifier

         Tray.TileData memory tileData = tray.getTile(tid, tileOffset);

        require(
            tileData.fontClass == 0, 
            "fontClass should be 0, which is emoji font class"
        );


        Namespace.CharacterData[] memory list = new Namespace.CharacterData[](
            1
        );

        list[0] = Namespace.CharacterData(tid, tileOffset, skinToneModifier);

        uint256 beforeBalance = note.balanceOf(owner);
        ns.fuse(list);
        uint256 afterBalance = note.balanceOf(owner);
        uint256 id = ns.nextNamespaceIDToMint();

        // tokenToName
        string memory name = ns.tokenToName(id);
        assertGt(bytes(name).length, 0);
        // nameToToken
        assertEq(ns.nameToToken(name), id);
        // trays should be burned
        vm.expectRevert(
            abi.encodeWithSelector(OwnerQueryForNonexistentToken.selector)
        );
        tray.ownerOf(tid);
        // check costs
        assertEq(afterBalance, beforeBalance - calcFusingCosts(1));

    }

}
