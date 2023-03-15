// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";
import {stdError} from "forge-std/stdlib.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import "../CidNFT.sol";
import "../SubprotocolRegistry.sol";
import "../AddressRegistry.sol";
import "./mock/MockERC20.sol";
import "./mock/SubprotocolNFT.sol";

contract CidNFTTest is DSTest, ERC721TokenReceiver {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    event OrderedDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );
    event OrderedDataRemoved(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );
    event ActiveDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 subprotocolNFTID,
        uint256 arrayIndex
    );

    Utilities internal utils;
    address payable[] internal users;

    address internal feeWallet;
    address internal user1;
    address internal user2;
    string internal constant BASE_URI = "tbd://base_uri/";

    MockToken internal note;
    SubprotocolRegistry internal subprotocolRegistry;
    SubprotocolNFT internal sub1;
    SubprotocolNFT internal sub2;
    CidNFT internal cidNFT;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        (feeWallet, user1, user2) = (users[0], users[1], users[2]);

        note = new MockToken();
        subprotocolRegistry = new SubprotocolRegistry(address(note), feeWallet);
        cidNFT = new CidNFT("MockCidNFT", "MCNFT", BASE_URI, feeWallet, address(note), address(subprotocolRegistry));
        AddressRegistry addressRegistry = new AddressRegistry(address(cidNFT));
        cidNFT.setAddressRegistry(address(addressRegistry));
        sub1 = new SubprotocolNFT();
        sub2 = new SubprotocolNFT();

        note.mint(user1, 10000 * 1e18);
        vm.startPrank(user1);
        note.approve(address(subprotocolRegistry), type(uint256).max);
        subprotocolRegistry.register(true, true, true, address(sub1), "sub1", 0);
        subprotocolRegistry.register(true, true, true, address(sub2), "sub2", 0);
        vm.stopPrank();
    }

    function testAddID0() public {
        // Should revert if trying to add NFT ID 0
        vm.expectRevert(abi.encodeWithSelector(CidNFT.NotAuthorizedForCIDNFT.selector, address(this), 0, address(0)));
        cidNFT.add(0, "sub1", 1, 1, CidNFT.AssociationType.ORDERED);
    }

    function testAddNonExistingSubprotocol() public {
        // Should revert if add data for non-existing subprotocol
        vm.expectRevert(abi.encodeWithSelector(CidNFT.SubprotocolDoesNotExist.selector, "NonExisting"));
        cidNFT.add(0, "NonExisting", 1, 1, CidNFT.AssociationType.ORDERED);
    }

    function testRemoveNonExistingSubprotocol() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));
        // Should revert if remove with non-existing subprotocol
        vm.expectRevert(abi.encodeWithSelector(CidNFT.SubprotocolDoesNotExist.selector, "NonExisting"));
        cidNFT.remove(tokenId, "NonExisting", 1, 1, CidNFT.AssociationType.ORDERED);
    }

    function testCannotRemoveNonExistingEntry() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));

        // NFT id that does not exist
        uint256 nftIDToRemove = 1;

        // Should revert when non-existing entry is inputted
        vm.expectRevert(
            abi.encodeWithSelector(CidNFT.ActiveArrayDoesNotContainID.selector, tokenId, "sub1", nftIDToRemove)
        );
        cidNFT.remove(tokenId, "sub1", 0, nftIDToRemove, CidNFT.AssociationType.ACTIVE);
    }

    function testCannotRemoveWhenOrderedOrActiveNotSet() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));

        uint256 key = 1;

        // Trying to remove when ORDERED value not set should revert
        vm.expectRevert(abi.encodeWithSelector(CidNFT.OrderedValueNotSet.selector, tokenId, "sub1", key));
        cidNFT.remove(tokenId, "sub1", key, 1, CidNFT.AssociationType.ORDERED);

        // Since PRIMARY value is not set, it should revert
        vm.expectRevert(abi.encodeWithSelector(CidNFT.PrimaryValueNotSet.selector, tokenId, "sub2"));
        cidNFT.remove(tokenId, "sub2", key, 1, CidNFT.AssociationType.PRIMARY);
    }

    function testMintWithoutAddList() public {
        // mint by this
        cidNFT.mint(new CidNFT.MintAddData[](0));
        uint256 tokenId = cidNFT.numMinted();
        assertEq(cidNFT.ownerOf(tokenId), address(this));

        // mint by user1
        vm.startPrank(user1);
        cidNFT.mint(new CidNFT.MintAddData[](0));
        tokenId = cidNFT.numMinted();
        assertEq(cidNFT.ownerOf(tokenId), user1);
        vm.stopPrank();
    }

    function testMintWithSingleAddList() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        // tokenId not minted yet
        vm.expectRevert("NOT_MINTED");
        cidNFT.ownerOf(tokenId);

        // mint in subprotocol
        uint256 subId = tokenId;
        sub1.mint(address(this), subId);
        sub1.setApprovalForAll(address(cidNFT), true);

        CidNFT.MintAddData[] memory addList = new CidNFT.MintAddData[](1);
        addList[0] = CidNFT.MintAddData("sub1", 0, subId, CidNFT.AssociationType.ORDERED);
        cidNFT.mint(addList);
        // confirm mint
        assertEq(cidNFT.ownerOf(tokenId), address(this));
    }

    function testMintWithMultiAddItems() public {
        // add for other token id
        uint256 prevTokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));
        uint256 tokenId = cidNFT.numMinted() + 1;

        // mint in subprotocol
        uint256 sub1Id = 12;
        uint256 sub2Id = 34;
        uint256 prevPrimaryId = 56;
        sub1.mint(address(this), sub1Id);
        sub1.approve(address(cidNFT), sub1Id);
        sub2.mint(address(this), sub2Id);
        sub2.mint(address(this), prevPrimaryId);
        sub2.setApprovalForAll(address(cidNFT), true);
        (uint256 key1, uint256 key2) = (0, 1);

        CidNFT.MintAddData[] memory addList = new CidNFT.MintAddData[](3);
        addList[0] = CidNFT.MintAddData("sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        addList[1] = CidNFT.MintAddData("sub2", key2, sub2Id, CidNFT.AssociationType.ORDERED);
        addList[2] = CidNFT.MintAddData("sub2", 0, prevPrimaryId, CidNFT.AssociationType.PRIMARY);
        cidNFT.mint(addList);
        // confirm mint
        assertEq(cidNFT.ownerOf(tokenId), address(this));
        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
        (uint256 returnedKey1, uint256 returnedTokenId1) = cidNFT.getOrderedCIDNFT("sub1", sub1Id);
        assertEq(returnedKey1, key1);
        assertEq(returnedTokenId1, tokenId);
        assertEq(cidNFT.getOrderedData(tokenId, "sub2", key2), sub2Id);
        (uint256 returnedKey2, uint256 returnedTokenId2) = cidNFT.getOrderedCIDNFT("sub2", sub2Id);
        assertEq(returnedKey2, key2);
        assertEq(returnedTokenId2, tokenId);
        assertEq(cidNFT.getPrimaryData(tokenId, "sub2"), prevPrimaryId);
        assertEq(cidNFT.getPrimaryCIDNFT("sub2", prevPrimaryId), tokenId);
    }

    function testMintWithMultiAddItemsAndRevert() public {
        uint256 tokenId = cidNFT.numMinted() + 1;

        // mint in subprotocol
        uint256 sub1Id = 12;
        uint256 sub2Id = 34;
        sub1.mint(address(this), sub1Id);
        sub1.approve(address(cidNFT), sub1Id);
        sub2.mint(address(this), sub2Id);
        // sub2 not approved
        // sub2.approve(address(cidNFT), sub2Id);
        (uint256 key1, uint256 key2) = (0, 1);

        CidNFT.MintAddData[] memory addList = new CidNFT.MintAddData[](2);
        addList[0] = CidNFT.MintAddData("sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        addList[1] = CidNFT.MintAddData("sub2", key2, sub2Id, CidNFT.AssociationType.ORDERED);

        // revert by add[1]
        vm.expectRevert("NOT_AUTHORIZED");
        cidNFT.mint(addList);
        // tokenId of CidNFT is not minted
        vm.expectRevert("NOT_MINTED");
        cidNFT.ownerOf(tokenId);
        // confirm data - not added
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), 0);
        (uint256 returnedKey1, uint256 returnedTokenId1) = cidNFT.getOrderedCIDNFT("sub1", sub1Id);
        assertEq(returnedTokenId1, 0);
        assertEq(cidNFT.getOrderedData(tokenId, "sub2", key2), 0);
        (uint256 returnedKey2, uint256 returnedTokenId2) = cidNFT.getOrderedCIDNFT("sub2", sub2Id);
        assertEq(returnedTokenId2, 0);
        // sub NFTs are not transferred
        assertEq(sub1.ownerOf(sub1Id), address(this));
        assertEq(sub2.ownerOf(sub2Id), address(this));
    }

    function prepareAddOne(address cidOwner, address subOwner)
        internal
        returns (
            uint256 tokenId,
            uint256 sub1Id,
            uint256 key1
        )
    {
        // mint without add
        tokenId = cidNFT.numMinted() + 1;

        vm.expectRevert("NOT_MINTED");
        cidNFT.ownerOf(tokenId);
        vm.prank(cidOwner);
        cidNFT.mint(new CidNFT.MintAddData[](0));

        // mint in subprotocol
        sub1Id = tokenId;
        sub1.mint(subOwner, sub1Id);
        vm.prank(subOwner);
        sub1.approve(address(cidNFT), sub1Id);
        key1 = 1;
    }

    function testAddRemoveByOwner() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(address(this), address(this));

        // add by owner
        assertEq(cidNFT.ownerOf(tokenId), address(this));
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
        (uint256 returnedKey1, uint256 returnedTokenId1) = cidNFT.getOrderedCIDNFT("sub1", sub1Id);
        assertEq(returnedKey1, key1);
        assertEq(returnedTokenId1, tokenId);

        // remove by owner
        vm.expectEmit(true, true, true, true);
        emit OrderedDataRemoved(tokenId, "sub1", key1, sub1Id);
        cidNFT.remove(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
    }

    function testAddDuplicate() public {
        address user = user1;
        (uint256 tokenId, uint256 subId, uint256 key) = prepareAddOne(user, user);

        // Add Once
        vm.startPrank(user);
        cidNFT.add(tokenId, "sub1", key, subId, CidNFT.AssociationType.ACTIVE);
        vm.stopPrank();

        // Transfer the sub nft back to the user, this should not happen normally
        // since the sub nft should stay in the cid nft unless it got removed
        // but the SubprotocolNFT can have arbitrary logic e.g. admin right
        vm.startPrank(address(cidNFT));
        sub1.safeTransferFrom(address(cidNFT), user, subId);
        vm.stopPrank();

        // Add Twice and expect it to revert with ActiveArrayAlreadyContainsID
        vm.startPrank(user);
        sub1.approve(address(cidNFT), subId);
        vm.expectRevert(abi.encodeWithSelector(CidNFT.ActiveArrayAlreadyContainsID.selector, tokenId, "sub1", subId));
        cidNFT.add(tokenId, "sub1", key, subId, CidNFT.AssociationType.ACTIVE);
        vm.stopPrank();
    }

    function testAddRemoveByApprovedAccount() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(address(this), user1);
        cidNFT.approve(user1, tokenId);

        // add by approved account
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
        (uint256 returnedKey1, uint256 returnedTokenId1) = cidNFT.getOrderedCIDNFT("sub1", sub1Id);
        assertEq(returnedKey1, key1);
        assertEq(returnedTokenId1, tokenId);

        // remove by approved account
        vm.expectEmit(true, true, true, true);
        emit OrderedDataRemoved(tokenId, "sub1", key1, sub1Id);
        cidNFT.remove(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();
    }

    function testAddRemoveByApprovedAllAccount() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(address(this), user2);
        cidNFT.setApprovalForAll(user2, true);

        // add by approved all account
        vm.startPrank(user2);
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
        (uint256 returnedKey1, uint256 returnedTokenId1) = cidNFT.getOrderedCIDNFT("sub1", sub1Id);
        assertEq(returnedKey1, key1);
        assertEq(returnedTokenId1, tokenId);

        // remove by approved all account
        vm.expectEmit(true, true, true, true);
        emit OrderedDataRemoved(tokenId, "sub1", key1, sub1Id);
        cidNFT.remove(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();
    }

    function testAddRemoveByUnauthorizedAccount() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(address(this), user2);

        // add by unauthorized account
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(CidNFT.NotAuthorizedForCIDNFT.selector, user2, tokenId, address(this)));
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();

        // approve and add
        cidNFT.setApprovalForAll(user2, true);
        vm.startPrank(user2);
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();

        // remove by unauthorized account
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(CidNFT.NotAuthorizedForCIDNFT.selector, user1, tokenId, address(this)));
        cidNFT.remove(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();
    }

    function tryAddType(
        bool valid,
        string memory subName,
        CidNFT.AssociationType aType
    ) internal {
        (uint256 tokenId, uint256 sub1Id, uint256 key) = prepareAddOne(address(this), address(this));
        if (!valid) {
            vm.expectRevert(
                abi.encodeWithSelector(CidNFT.AssociationTypeNotSupportedForSubprotocol.selector, aType, subName)
            );
        }
        cidNFT.add(tokenId, subName, key, sub1Id, aType);
    }

    function testAddUnsupportedAssociationType() public {
        // register different subprotocols
        vm.startPrank(user1);
        subprotocolRegistry.register(true, false, false, address(sub1), "OrderedOnly", 0);
        subprotocolRegistry.register(false, true, false, address(sub1), "PrimaryOnly", 0);
        subprotocolRegistry.register(false, false, true, address(sub1), "ActiveOnly", 0);
        subprotocolRegistry.register(true, true, false, address(sub1), "OrderedAndPrimary", 0);
        subprotocolRegistry.register(true, false, true, address(sub1), "OrderedAndActive", 0);
        subprotocolRegistry.register(false, true, true, address(sub1), "PrimaryAndActive", 0);
        subprotocolRegistry.register(true, true, true, address(sub1), "AllTypes", 0);
        vm.stopPrank();

        // OrderedOnly
        tryAddType(true, "OrderedOnly", CidNFT.AssociationType.ORDERED);
        tryAddType(false, "OrderedOnly", CidNFT.AssociationType.PRIMARY);
        tryAddType(false, "OrderedOnly", CidNFT.AssociationType.ACTIVE);
        // PrimaryOnly
        tryAddType(false, "PrimaryOnly", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "PrimaryOnly", CidNFT.AssociationType.PRIMARY);
        tryAddType(false, "PrimaryOnly", CidNFT.AssociationType.ACTIVE);
        // ActiveOnly
        tryAddType(false, "ActiveOnly", CidNFT.AssociationType.ORDERED);
        tryAddType(false, "ActiveOnly", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "ActiveOnly", CidNFT.AssociationType.ACTIVE);
        // OrderedAndPrimary
        tryAddType(true, "OrderedAndPrimary", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "OrderedAndPrimary", CidNFT.AssociationType.PRIMARY);
        tryAddType(false, "OrderedAndPrimary", CidNFT.AssociationType.ACTIVE);
        // OrderedAndActive
        tryAddType(true, "OrderedAndActive", CidNFT.AssociationType.ORDERED);
        tryAddType(false, "OrderedAndActive", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "OrderedAndActive", CidNFT.AssociationType.ACTIVE);
        // PrimaryAndActive
        tryAddType(false, "PrimaryAndActive", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "PrimaryAndActive", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "PrimaryAndActive", CidNFT.AssociationType.ACTIVE);
        // AllTypes
        tryAddType(true, "AllTypes", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "AllTypes", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "AllTypes", CidNFT.AssociationType.ACTIVE);
    }

    function testAddRemoveOrderedType() public {
        address user = user1;
        (uint256 tokenId, uint256 subId, uint256 key) = prepareAddOne(user, user);
        vm.startPrank(user);
        cidNFT.add(tokenId, "sub1", key, subId, CidNFT.AssociationType.ORDERED);
        // check add result
        assertEq(sub1.ownerOf(subId), address(cidNFT));
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key), subId);
        (uint256 returnedKey, uint256 returnedTokenId) = cidNFT.getOrderedCIDNFT("sub1", subId);
        assertEq(returnedKey, key);
        assertEq(returnedTokenId, tokenId);
        // remove
        cidNFT.remove(tokenId, "sub1", key, subId, CidNFT.AssociationType.ORDERED);
        // check remove result
        assertEq(sub1.ownerOf(subId), user);
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key), 0);
        (returnedKey, returnedTokenId) = cidNFT.getOrderedCIDNFT("sub1", subId);
        assertEq(returnedTokenId, 0);
        vm.stopPrank();
    }

    function testAddRemovePrimaryType() public {
        address user = user1;
        (uint256 tokenId, uint256 subId, uint256 key) = prepareAddOne(user, user);
        vm.startPrank(user);
        cidNFT.add(tokenId, "sub1", key, subId, CidNFT.AssociationType.PRIMARY);
        // check add result
        assertEq(sub1.ownerOf(subId), address(cidNFT));
        assertEq(cidNFT.getPrimaryData(tokenId, "sub1"), subId);
        assertEq(cidNFT.getPrimaryCIDNFT("sub1", subId), tokenId);
        // remove
        cidNFT.remove(tokenId, "sub1", key, subId, CidNFT.AssociationType.PRIMARY);
        // check remove result
        assertEq(sub1.ownerOf(subId), user);
        assertEq(cidNFT.getPrimaryData(tokenId, "sub1"), 0);
        assertEq(cidNFT.getPrimaryCIDNFT("sub1", subId), 0);
        vm.stopPrank();
    }

    function testAddRemoveActiveType() public {
        address user = user1;
        (uint256 tokenId, uint256 subId, uint256 key) = prepareAddOne(user, user);
        vm.startPrank(user);
        cidNFT.add(tokenId, "sub1", key, subId, CidNFT.AssociationType.ACTIVE);
        {
            // check add result
            assertEq(sub1.ownerOf(subId), address(cidNFT));
            uint256[] memory values = cidNFT.getActiveData(tokenId, "sub1");
            assertEq(values.length, 1);
            assertTrue(cidNFT.activeDataIncludesNFT(tokenId, "sub1", subId));
            (uint256 position, uint256 cidNFTTokenID) = cidNFT.getActiveCIDNFT("sub1", subId);
            assertEq(position, 0);
            assertEq(cidNFTTokenID, tokenId);
        }
        // remove
        cidNFT.remove(tokenId, "sub1", key, subId, CidNFT.AssociationType.ACTIVE);
        {
            // check remove result
            assertEq(sub1.ownerOf(subId), user);
            uint256[] memory values = cidNFT.getActiveData(tokenId, "sub1");
            assertEq(values.length, 0);
            assertTrue(!cidNFT.activeDataIncludesNFT(tokenId, "sub1", subId));
            (uint256 position, uint256 cidNFTTokenID) = cidNFT.getActiveCIDNFT("sub1", subId);
            assertEq(cidNFTTokenID, 0);
        }
        vm.stopPrank();
    }

    function addMultipleActiveTypeValues(address user, uint256 count)
        internal
        returns (uint256 tokenId, uint256[] memory subIds)
    {
        vm.startPrank(user);
        // mint without add
        tokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));

        // prepare subprotocol NFTs
        subIds = new uint256[](count);
        for (uint256 i = 0; i < subIds.length; i++) {
            subIds[i] = 123 + i;
            sub1.mint(user, subIds[i]);
        }
        sub1.setApprovalForAll(address(cidNFT), true);
        // add all
        for (uint256 i = 0; i < subIds.length; i++) {
            // check event
            vm.expectEmit(true, true, false, true);
            emit ActiveDataAdded(tokenId, "sub1", subIds[i], i);
            // add 1
            cidNFT.add(tokenId, "sub1", 0, subIds[i], CidNFT.AssociationType.ACTIVE);
            // check subprotocol NFT owner
            assertEq(sub1.ownerOf(subIds[i]), address(cidNFT));
        }
        // check data
        checkActiveValues(tokenId, "sub1", subIds, subIds.length);
        vm.stopPrank();
    }

    function testAddMultipleActiveTypeValues() public {
        addMultipleActiveTypeValues(user1, 10);
    }

    function checkActiveValues(
        uint256 tokenId,
        string memory subName,
        uint256[] memory expectedIds,
        uint256 count
    ) internal {
        uint256[] memory values = cidNFT.getActiveData(tokenId, subName);
        assertEq(values.length, count);
        for (uint256 i = 0; i < count; i++) {
            assertEq(values[i], expectedIds[i]);
            (uint256 position, uint256 cidNFTTokenID) = cidNFT.getActiveCIDNFT(subName, expectedIds[i]);
            assertEq(position, i);
            assertEq(cidNFTTokenID, tokenId);
        }
    }

    function testRemoveActiveValues() public {
        address user = user1;
        (uint256 tokenId, uint256[] memory expectedIds) = addMultipleActiveTypeValues(user, 10);
        uint256 remain = 10;
        vm.startPrank(user);

        // remove first item
        cidNFT.remove(tokenId, "sub1", 0, expectedIds[0], CidNFT.AssociationType.ACTIVE);
        expectedIds[0] = expectedIds[--remain];
        checkActiveValues(tokenId, "sub1", expectedIds, remain);

        // remove middle item
        cidNFT.remove(tokenId, "sub1", 0, expectedIds[3], CidNFT.AssociationType.ACTIVE);
        expectedIds[3] = expectedIds[--remain];
        checkActiveValues(tokenId, "sub1", expectedIds, remain);

        // remove last item
        cidNFT.remove(tokenId, "sub1", 0, expectedIds[remain - 1], CidNFT.AssociationType.ACTIVE);
        remain--;
        checkActiveValues(tokenId, "sub1", expectedIds, remain);

        // remove all item
        for (; remain > 0; remain--) {
            cidNFT.remove(tokenId, "sub1", 0, expectedIds[remain - 1], CidNFT.AssociationType.ACTIVE);
        }
        checkActiveValues(tokenId, "sub1", new uint256[](0), remain);

        vm.stopPrank();
    }

    function testOverwritingOrdered() public {
        address user = user2;
        vm.startPrank(user);

        // mint two nft for user
        (uint256 nft1, uint256 nft2) = (101, 102);
        sub1.mint(user, nft1);
        sub1.mint(user, nft2);
        sub1.setApprovalForAll(address(cidNFT), true);
        // mint CidNFT
        uint256 cid = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));
        uint256 key = 111;

        // add nft1 to CidNFT a key
        cidNFT.add(cid, "sub1", key, nft1, CidNFT.AssociationType.ORDERED);
        assertEq(sub1.ownerOf(nft1), address(cidNFT));
        // add nft2 to CidNFT with the same key
        cidNFT.add(cid, "sub1", key, nft2, CidNFT.AssociationType.ORDERED);

        // nft1 should be transferred back to user
        assertEq(sub1.ownerOf(nft1), user);
        // nft2 should still be in protocol
        assertEq(sub1.ownerOf(nft2), address(cidNFT));

        vm.stopPrank();
    }

    function testOverWritingPrimary() public {
        address user = user2;
        vm.startPrank(user);

        // mint two nft for user
        (uint256 nft1, uint256 nft2) = (101, 102);
        sub1.mint(user, nft1);
        sub1.mint(user, nft2);
        sub1.setApprovalForAll(address(cidNFT), true);
        // mint CidNFT
        uint256 cid = cidNFT.numMinted() + 1;
        cidNFT.mint(new CidNFT.MintAddData[](0));
        // key is useless when adding PRIMARY type
        uint256 key = 111;

        // add nft1 to CidNFT
        cidNFT.add(cid, "sub1", key, nft1, CidNFT.AssociationType.PRIMARY);
        // add nft2 to CidNFT
        cidNFT.add(cid, "sub1", key, nft2, CidNFT.AssociationType.PRIMARY);

        // nft1 should be transferred back to user
        assertEq(sub1.ownerOf(nft1), user);
        // nft2 should still be in protocol
        assertEq(sub1.ownerOf(nft2), address(cidNFT));

        vm.stopPrank();
    }

    function testAddWithNotEnoughFee() public {
        uint96 subFee = 10 * 1e18;
        vm.startPrank(user1);
        subprotocolRegistry.register(true, true, true, address(sub1), "SubWithFee", subFee);
        vm.stopPrank();

        (uint256 tokenId, uint256 subId, uint256 key) = prepareAddOne(user2, user2);
        vm.startPrank(user2);
        note.approve(address(cidNFT), type(uint256).max);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        cidNFT.add(tokenId, "SubWithFee", key, subId, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();
    }

    function testAddWithFee() public {
        uint96 subFee = 10 * 1e18;
        vm.startPrank(user1);
        subprotocolRegistry.register(true, true, true, address(sub1), "SubWithFee", subFee);
        vm.stopPrank();

        // mint fee
        note.mint(user2, 1000 * 1e18);

        // record balances
        uint256 balUser = note.balanceOf(user2);
        uint256 balFeeWallet = note.balanceOf(feeWallet);
        uint256 balSubOwner = note.balanceOf(user1);

        (uint256 tokenId, uint256 subId, uint256 key) = prepareAddOne(user2, user2);
        vm.startPrank(user2);
        note.approve(address(cidNFT), type(uint256).max);
        // add event
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "SubWithFee", key, subId);
        cidNFT.add(tokenId, "SubWithFee", key, subId, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();
        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "SubWithFee", key), subId);
        (uint256 returnedKey, uint256 returnedTokenId) = cidNFT.getOrderedCIDNFT("SubWithFee", subId);
        assertEq(returnedKey, key);
        assertEq(returnedTokenId, tokenId);

        // check fee flow
        assertEq(note.balanceOf(user2), balUser - subFee);
        uint256 cidFee = (subFee * cidNFT.CID_FEE_BPS()) / 10_000;
        assertEq(note.balanceOf(feeWallet), balFeeWallet + cidFee);
        assertEq(note.balanceOf(user1), balSubOwner + subFee - cidFee);
    }

    function testTokenURI() public {
        uint256 id1 = cidNFT.numMinted() + 1;
        uint256 id2 = cidNFT.numMinted() + 2;
        uint256 nonExistId = cidNFT.numMinted() + 3;
        // mint id1
        cidNFT.mint(new CidNFT.MintAddData[](0));
        // mint id2
        cidNFT.mint(new CidNFT.MintAddData[](0));

        // exist id
        assertEq(cidNFT.tokenURI(id1), BASE_URI);
        assertEq(cidNFT.tokenURI(id2), BASE_URI);

        // non-exist id
        vm.expectRevert(abi.encodeWithSelector(CidNFT.TokenNotMinted.selector, nonExistId));
        cidNFT.tokenURI(nonExistId);
    }

    function testTransferWithoutRegistered() public {
        // mint by this
        cidNFT.mint(new CidNFT.MintAddData[](0));
        uint256 tokenId = cidNFT.numMinted();
        assertEq(cidNFT.ownerOf(tokenId), address(this));

        // mint by user1
        vm.startPrank(user1);
        cidNFT.mint(new CidNFT.MintAddData[](0));
        tokenId = cidNFT.numMinted();
        assertEq(cidNFT.ownerOf(tokenId), user1);
        cidNFT.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
    }

    function testCallingSetAddressRegistryFromNonOwner() public {
        CidNFT cidNFT2 = new CidNFT(
            "MockCidNFT2",
            "MCNFT2",
            BASE_URI,
            feeWallet,
            address(note),
            address(subprotocolRegistry)
        );
        vm.prank(user1);
        vm.expectRevert("UNAUTHORIZED");
        cidNFT2.setAddressRegistry(address(0));
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
