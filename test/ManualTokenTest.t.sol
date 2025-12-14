// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ManualToken} from "../src/ManualToken.sol";

contract ManualTokenTest is Test {
    ManualToken internal token;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000e18;
    uint256 internal constant STARTING_BALANCE = 100e18;

    address internal bob = makeAddr("bob");
    address internal alice = makeAddr("alice");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        token = new ManualToken("ManualToken", "MTK");

        bool ok = token.transfer(bob, STARTING_BALANCE);
        assertTrue(ok);
    }

    function testMetadataAndInitialSupply() public view {
        assertEq(token.name(), "ManualToken");
        assertEq(token.symbol(), "MTK");
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(
            token.balanceOf(address(this)),
            INITIAL_SUPPLY - STARTING_BALANCE
        );
    }

    function testTransferEmitsEventAndUpdatesBalances() public {
        uint256 amount = 5e18;

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(bob, alice, amount);

        vm.prank(bob);
        bool ok = token.transfer(alice, amount);
        assertTrue(ok);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(bob), STARTING_BALANCE - amount);
    }

    function testTransferRevertsOnZeroReceiver() public {
        vm.expectRevert(bytes("ERC20: Transfer to the zero address"));
        vm.prank(bob);
        token.transfer(address(0), 1);
    }

    function testTransferRevertsWhenInsufficientBalance() public {
        vm.expectRevert(bytes("ERC20: Transfer amount exceed the balance"));
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    function testApproveEmitsEventAndSetsAllowance() public {
        uint256 allowanceAmount = 123e18;

        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(bob, alice, allowanceAmount);

        vm.prank(bob);
        bool ok = token.approve(alice, allowanceAmount);
        assertTrue(ok);

        assertEq(token.allowance(bob, alice), allowanceAmount);
    }

    function testTransferFromDecrementsAllowanceAndMovesFunds() public {
        uint256 allowanceAmount = 100e18;
        uint256 spendAmount = 40e18;

        vm.prank(bob);
        bool approved = token.approve(alice, allowanceAmount);
        assertTrue(approved);

        vm.prank(alice);
        bool ok = token.transferFrom(bob, alice, spendAmount);
        assertTrue(ok);

        assertEq(token.balanceOf(alice), spendAmount);
        assertEq(token.balanceOf(bob), STARTING_BALANCE - spendAmount);
        assertEq(token.allowance(bob, alice), allowanceAmount - spendAmount);
    }

    function testTransferFromRevertsWhenAllowanceTooLow() public {
        vm.prank(bob);
        bool approved = token.approve(alice, 1);
        assertTrue(approved);

        vm.expectRevert(bytes("ERC20: insufficient allowance"));
        vm.prank(alice);
        token.transferFrom(bob, alice, 2);
    }

    function testInfiniteApprovalIsNotDecremented() public {
        vm.prank(bob);
        bool approved = token.approve(alice, type(uint256).max);
        assertTrue(approved);

        vm.prank(alice);
        bool ok = token.transferFrom(bob, alice, 10e18);
        assertTrue(ok);

        assertEq(token.allowance(bob, alice), type(uint256).max);
    }

    function testIncreaseDecreaseAllowance() public {
        vm.prank(bob);
        assertTrue(token.approve(alice, 10));

        vm.prank(bob);
        assertTrue(token.increaseAllowance(alice, 7));
        assertEq(token.allowance(bob, alice), 17);

        vm.prank(bob);
        assertTrue(token.decreaseAllowance(alice, 5));
        assertEq(token.allowance(bob, alice), 12);
    }

    function testDecreaseAllowanceRevertsBelowZero() public {
        vm.prank(bob);
        assertTrue(token.approve(alice, 3));

        vm.expectRevert(bytes("decreased allowance below 0"));
        vm.prank(bob);
        token.decreaseAllowance(alice, 4);
    }

    function testFuzzTransfersConserveSupply(
        uint96 rawAmount1,
        uint96 rawAmount2
    ) public {
        uint256 amount1 = bound(
            uint256(rawAmount1),
            0,
            token.balanceOf(address(this))
        );
        uint256 amount2 = bound(uint256(rawAmount2), 0, token.balanceOf(bob));

        bool ok1 = token.transfer(alice, amount1);
        assertTrue(ok1);

        vm.prank(bob);
        bool ok2 = token.transfer(alice, amount2);
        assertTrue(ok2);

        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(
            token.balanceOf(address(this)) +
                token.balanceOf(bob) +
                token.balanceOf(alice),
            INITIAL_SUPPLY
        );
    }
}
