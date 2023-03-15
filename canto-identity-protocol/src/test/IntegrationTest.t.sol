// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";
import {stdError} from "forge-std/stdlib.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import "../CidNFT.sol";
import "../SubprotocolRegistry.sol";
import "../AddressRegistry.sol";
import "./mock/MockERC20.sol";
import "./mock/SubprotocolNFT.sol";

contract IntegrationTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    address internal feeWallet;
    address internal user1;
    address internal user2;
    address internal user3;
    address internal alice;
    address internal bob;
    string internal constant BASE_URI = "tbd://base_uri/";

    MockToken internal note;
    SubprotocolRegistry internal subprotocolRegistry;
    AddressRegistry internal addressRegistry;
    SubprotocolNFT internal sub1;
    SubprotocolNFT internal sub2;
    SubprotocolNFT internal sub3;
    CidNFT internal cidNFT;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(6);

        feeWallet = users[0];
        user1 = users[1];
        user2 = users[2];
        user3 = users[3];
        alice = users[4];
        bob = users[5];

        note = new MockToken();
        subprotocolRegistry = new SubprotocolRegistry(address(note), feeWallet);
        cidNFT = new CidNFT("MockCidNFT", "MCNFT", BASE_URI, feeWallet, address(note), address(subprotocolRegistry));
        addressRegistry = new AddressRegistry(address(cidNFT));

        sub1 = new SubprotocolNFT();
        sub2 = new SubprotocolNFT();
        sub3 = new SubprotocolNFT();

        vm.startPrank(alice);

        sub1.mint(alice, 1);
        sub1.setApprovalForAll(address(cidNFT), true);

        sub2.mint(alice, 2);
        sub2.setApprovalForAll(address(cidNFT), true);

        sub3.mint(alice, 3);
        sub3.setApprovalForAll(address(cidNFT), true);

        note.approve(address(cidNFT), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        sub1.mint(bob, 11);
        sub1.setApprovalForAll(address(cidNFT), true);

        sub2.mint(bob, 12);
        sub2.setApprovalForAll(address(cidNFT), true);

        sub3.mint(bob, 13);
        sub3.setApprovalForAll(address(cidNFT), true);

        note.approve(address(cidNFT), type(uint256).max);
        vm.stopPrank();

        // Three different EOAs create three different subprotocols.
        note.mint(user1, 100000 * 1e18);
        note.mint(user2, 100000 * 1e18);
        note.mint(user3, 100000 * 1e18);
        note.mint(alice, 100000 * 1e18);
        note.mint(bob, 100000 * 1e18);

        vm.startPrank(user1);
        note.approve(address(subprotocolRegistry), type(uint256).max);
        subprotocolRegistry.register(true, true, true, address(sub1), "sub1", 0);
        vm.stopPrank();

        vm.startPrank(user2);
        note.approve(address(subprotocolRegistry), type(uint256).max);
        subprotocolRegistry.register(true, false, true, address(sub2), "sub2", 100);
        vm.stopPrank();

        vm.startPrank(user3);
        note.approve(address(subprotocolRegistry), type(uint256).max);
        subprotocolRegistry.register(false, false, true, address(sub3), "sub3", 250);
        vm.stopPrank();
    }

    function testIntegrationCaseOne() public {
        // Alice mints a CID NFT and registers it in the address registry.

        uint256 nftIdOne = 1;

        vm.startPrank(alice);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);

        addressRegistry.register(nftIdOne);

        uint256 cid = addressRegistry.getCID(alice);
        assertEq(cid, nftIdOne);

        //  She then adds some subprotocol NFTs to her CID NFT
        cidNFT.add(nftIdOne, "sub1", 0, 1, CidNFT.AssociationType.PRIMARY);
        assertEq(sub1.ownerOf(1), address(cidNFT));

        cidNFT.add(nftIdOne, "sub2", 10, 2, CidNFT.AssociationType.ORDERED);
        assertEq(sub2.ownerOf(2), address(cidNFT));

        cidNFT.add(nftIdOne, "sub3", 0, 3, CidNFT.AssociationType.ACTIVE);
        assertEq(sub3.ownerOf(3), address(cidNFT));

        // She removes them again.
        cidNFT.remove(nftIdOne, "sub1", 0, 1, CidNFT.AssociationType.PRIMARY);
        assertEq(sub1.ownerOf(1), alice);

        cidNFT.remove(nftIdOne, "sub2", 10, 2, CidNFT.AssociationType.ORDERED);
        assertEq(sub2.ownerOf(2), alice);

        cidNFT.remove(nftIdOne, "sub3", 0, 3, CidNFT.AssociationType.ACTIVE);
        assertEq(sub3.ownerOf(3), alice);
    }

    function testIntegrationCaseTwo() public {
        // Bob adds some subprotocol NFTs to his CID NFT that is registered in the address registry.

        uint256 nftIdOne = 1;

        vm.startPrank(bob);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);

        addressRegistry.register(nftIdOne);

        uint256 cid = addressRegistry.getCID(bob);
        assertEq(cid, nftIdOne);

        cidNFT.add(nftIdOne, "sub1", 0, 11, CidNFT.AssociationType.PRIMARY);
        assertEq(sub1.ownerOf(11), address(cidNFT));

        cidNFT.add(nftIdOne, "sub2", 10, 12, CidNFT.AssociationType.ORDERED);
        assertEq(sub2.ownerOf(12), address(cidNFT));

        // he mints a new CID NFT, registers that one in the address registry
        uint256 nftIdTwo = 2;
        cidNFT.mint(addList);

        addressRegistry.register(nftIdTwo);

        cid = addressRegistry.getCID(bob);
        assertEq(cid, nftIdTwo);

        // and adds/removes some other subprotocol NFTs.
        cidNFT.add(nftIdOne, "sub3", 0, 13, CidNFT.AssociationType.ACTIVE);
        assertEq(sub3.ownerOf(13), address(cidNFT));

        cidNFT.remove(nftIdOne, "sub2", 10, 12, CidNFT.AssociationType.ORDERED);
        assertEq(sub2.ownerOf(12), bob);

        cidNFT.remove(nftIdOne, "sub3", 0, 13, CidNFT.AssociationType.ACTIVE);
        assertEq(sub3.ownerOf(13), bob);
    }
}
