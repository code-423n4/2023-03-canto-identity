// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import "../AddressRegistry.sol";
import "../SubprotocolRegistry.sol";
import "./mock/MockERC20.sol";
import "./mock/SubprotocolNFT.sol";
import "./mock/NotCompliantNFT.sol";

contract SubprotocolRegistryTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    AddressRegistry internal addressRegistry;

    SubprotocolRegistry subprotocolRegistry;
    MockToken token;

    address feeWallet;
    address user1;
    address user2;

    uint256 feeAmount;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        user1 = users[0];
        user2 = users[1];
        feeWallet = users[2];

        token = new MockToken();
        subprotocolRegistry = new SubprotocolRegistry(address(token), feeWallet);

        feeAmount = subprotocolRegistry.REGISTER_FEE();

        vm.prank(user1);
        token.approve(address(subprotocolRegistry), type(uint256).max);
        token.mint(user1, feeAmount * 100);
    }

    function testRegisterDifferentAssociation() public {
        vm.startPrank(user1);
        SubprotocolNFT subprotocolNFTOne = new SubprotocolNFT();
        subprotocolRegistry.register(true, false, false, address(subprotocolNFTOne), "subprotocol1", 0);

        assertEq(token.balanceOf(feeWallet), feeAmount);

        SubprotocolNFT subprotocolNFTTwo = new SubprotocolNFT();
        subprotocolRegistry.register(true, true, false, address(subprotocolNFTTwo), "subprotocol2", 100);

        assertEq(token.balanceOf(feeWallet), feeAmount * 2);

        subprotocolRegistry.register(true, true, true, address(subprotocolNFTTwo), "subprotocol3", 100);

        assertEq(token.balanceOf(feeWallet), feeAmount * 3);

        subprotocolRegistry.register(true, false, true, address(subprotocolNFTTwo), "subprotocol4", 5034);

        assertEq(token.balanceOf(feeWallet), feeAmount * 4);
    }

    function testRegisterExistedProtocol() public {
        vm.startPrank(user1);
        string memory name = "subprotocol1";
        SubprotocolNFT subprotocolNFTOne = new SubprotocolNFT();

        subprotocolRegistry.register(true, false, false, address(subprotocolNFTOne), name, 0);

        vm.expectRevert(abi.encodeWithSelector(SubprotocolRegistry.SubprotocolAlreadyExists.selector, name, user1));
        subprotocolRegistry.register(true, false, false, address(subprotocolNFTOne), name, 0);
    }

    function testReturnedDataMatchSubprotocol() public {
        vm.startPrank(user1);
        string memory name = "subprotocol1";
        uint96 subprotocolFee = 100;

        SubprotocolNFT subprotocolNFTOne = new SubprotocolNFT();

        subprotocolRegistry.register(true, true, false, address(subprotocolNFTOne), name, subprotocolFee);

        SubprotocolRegistry.SubprotocolData memory data = subprotocolRegistry.getSubprotocol(name);

        assertEq(data.owner, user1);
        assertEq(data.fee, subprotocolFee);
        assertEq(data.nftAddress, address(subprotocolNFTOne));
        assert(data.ordered == true);
        assert(data.primary == true);
        assert(data.active == false);
    }

    function testCannotRegisterWithoutTypeSpecified() public {
        vm.startPrank(user1);
        SubprotocolNFT subprotocolNFT = new SubprotocolNFT();
        string memory name = "test name";

        // Should revert if no type is specified
        vm.expectRevert(abi.encodeWithSelector(SubprotocolRegistry.NoTypeSpecified.selector, name));
        subprotocolRegistry.register(false, false, false, address(subprotocolNFT), name, 0);
    }

    function testRegisterNotSubprotocolCompliantNFT() public {
        vm.startPrank(user1);
        string memory name = "subprotocol1";
        NotCompliantNFT notCompliantNFT = new NotCompliantNFT();
        vm.expectRevert(abi.encodeWithSelector(SubprotocolRegistry.NotANFT.selector, address(notCompliantNFT)));
        subprotocolRegistry.register(true, false, false, address(notCompliantNFT), name, 0);
    }
}
