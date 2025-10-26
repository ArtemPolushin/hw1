// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {Bridge} from "../src/Bridge.sol";

contract BridgeTest is Test {
    MyToken token;
    Bridge bridge;

    address relayer = address(100);
    address user = address(200);
    address owner = address(this);

    bytes32 depositId = keccak256("testDeposit");
    event Deposit(
        bytes32 indexed depositId,
        address indexed from,
        uint256 amount,
        uint256 indexed toChainId,
        address to
    );
    event Redeem(
        bytes32 indexed depositId,
        address indexed to,
        uint256 amount,
        uint256 indexed fromChainId
    );
    event RelayerUpdated(
        address indexed oldRelayer,
        address indexed newRelayer
    );
    event TokenUpdated(address indexed oldToken, address indexed newToken);

    function setUp() public {
        token = new MyToken(owner);
        bridge = new Bridge(address(token), relayer, owner);
        token.mint(user, 1000 ether);
        token.transferOwnership(address(bridge));
        vm.prank(user);
        token.approve(address(bridge), 1000 ether);
    }

    function test_Deposit() public {
        uint256 initialBalance = token.balanceOf(user);

        vm.prank(user);
        bridge.deposit(depositId, 100 ether, 2, address(300));

        assertEq(token.balanceOf(user), initialBalance - 100 ether);
        assertTrue(bridge.processed(depositId));
    }

    function test_Redeem() public {
        bytes32 depId = keccak256("anotherDeposit");
        uint256 initialBalance = token.balanceOf(user);
        bridge.redeem(depId, user, 50 ether, 1);

        assertEq(token.balanceOf(user), initialBalance + 50 ether);
        assertTrue(bridge.processed(depId));
    }

    function test_Redeem_By_Relayer() public {
        bytes32 depId = keccak256("relayerDeposit");
        uint256 initialBalance = token.balanceOf(user);

        vm.prank(relayer);
        bridge.redeem(depId, user, 50 ether, 1);

        assertEq(token.balanceOf(user), initialBalance + 50 ether);
        assertTrue(bridge.processed(depId));
    }

    function test_Revert_When_Double_Redeem() public {
        bytes32 id = keccak256("dupDeposit");
        bridge.redeem(id, user, 10 ether, 1);
        vm.expectRevert("Redeem already processed");
        bridge.redeem(id, user, 10 ether, 1);
    }

    function test_Revert_When_Unauthorized_Redeem() public {
        address unauthorized = address(999);

        vm.prank(unauthorized);
        vm.expectRevert("Only relayer or owner");
        bridge.redeem(keccak256("bad"), user, 1 ether, 1);
    }

    function test_Full_Flow() public {
        MyToken token2 = new MyToken(owner);
        Bridge bridge2 = new Bridge(address(token2), relayer, owner);
        token2.transferOwnership(address(bridge2));

        uint256 initialBalance1 = token.balanceOf(user);

        vm.prank(user);
        bridge.deposit(depositId, 100 ether, 2, user);

        assertEq(token.balanceOf(user), initialBalance1 - 100 ether);

        vm.prank(relayer);
        bridge2.redeem(depositId, user, 100 ether, 1);

        assertEq(token2.balanceOf(user), 100 ether);
    }
}
