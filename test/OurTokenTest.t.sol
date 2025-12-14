// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    uint256 internal constant INITIAL_SUPPLY = 1_000_000e18;
    uint256 internal constant STARTING_BALANCE = 1000e18;

    bytes32 internal constant TRANSFER_EVENT_SIG =
        keccak256("Transfer(address,address,uint256)");

    address internal initialHolder;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        deployer = new DeployOurToken();

        vm.recordLogs();
        ourToken = deployer.run();
        initialHolder = _findInitialHolderFromMint(vm.getRecordedLogs());

        vm.prank(initialHolder);
        bool ok = ourToken.transfer(bob, STARTING_BALANCE);
        assertTrue(ok);
    }

    function testDeploymentMintsExpectedSupplyToInitialHolder() public {
        assertTrue(initialHolder != address(0));
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(
            ourToken.balanceOf(initialHolder),
            INITIAL_SUPPLY - STARTING_BALANCE
        );
    }

    function testMetadata() public view {
        assertEq(ourToken.name(), "MyToken");
        assertEq(ourToken.symbol(), "mtkn");
        assertEq(ourToken.decimals(), 18);
    }

    function testBobBalance() public {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testTransferEmitsEventAndUpdatesBalances() public {
        uint256 amount = 1e18;

        vm.expectEmit(true, true, false, true, address(ourToken));
        emit Transfer(initialHolder, alice, amount);

        vm.prank(initialHolder);
        bool ok = ourToken.transfer(alice, amount);
        assertTrue(ok);

        assertEq(ourToken.balanceOf(alice), amount);
    }

    function testTransferRevertsOnZeroReceiver() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector,
                address(0)
            )
        );
        vm.prank(initialHolder);
        ourToken.transfer(address(0), 1);
    }

    function testTransferRevertsWhenInsufficientBalance() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                alice,
                0,
                1
            )
        );
        vm.prank(alice);
        ourToken.transfer(bob, 1);
    }

    function testApproveRevertsOnZeroSpender() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidSpender.selector,
                address(0)
            )
        );
        vm.prank(bob);
        ourToken.approve(address(0), 1);
    }

    function testAllowanceWork() public {
        uint256 initialAllowance = 1000e18;

        vm.prank(bob);
        bool approved = ourToken.approve(alice, initialAllowance);
        assertTrue(approved);

        uint256 transferAmount = 500e18;

        vm.prank(alice);
        bool ok = ourToken.transferFrom(bob, alice, transferAmount);
        assertTrue(ok);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(
            ourToken.allowance(bob, alice),
            initialAllowance - transferAmount
        );
    }

    function testTransferFromRevertsWhenAllowanceTooLow() public {
        vm.prank(bob);
        bool approved = ourToken.approve(alice, 1);
        assertTrue(approved);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                alice,
                1,
                2
            )
        );
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 2);
    }

    function testInfiniteApprovalIsNotDecremented() public {
        vm.prank(bob);
        bool approved = ourToken.approve(alice, type(uint256).max);
        assertTrue(approved);

        vm.prank(alice);
        bool ok = ourToken.transferFrom(bob, alice, 123e18);
        assertTrue(ok);

        assertEq(ourToken.allowance(bob, alice), type(uint256).max);
    }

    function testFuzzTransferConservesTotalSupply(uint96 rawAmount) public {
        uint256 amount = uint256(rawAmount);
        uint256 holderBal = ourToken.balanceOf(initialHolder);
        amount = bound(amount, 0, holderBal);

        vm.prank(initialHolder);
        bool ok = ourToken.transfer(alice, amount);
        assertTrue(ok);

        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(
            ourToken.balanceOf(initialHolder) +
                ourToken.balanceOf(bob) +
                ourToken.balanceOf(alice),
            INITIAL_SUPPLY
        );
    }

    function testFuzzTransferFromSpendsAllowance(
        uint96 rawApprove,
        uint96 rawSpend
    ) public {
        uint256 approveAmount = uint256(rawApprove);
        uint256 bobBal = ourToken.balanceOf(bob);
        approveAmount = bound(approveAmount, 0, bobBal);

        vm.prank(bob);
        bool approved = ourToken.approve(alice, approveAmount);
        assertTrue(approved);

        uint256 spendAmount = uint256(rawSpend);
        spendAmount = bound(spendAmount, 0, approveAmount);

        vm.prank(alice);
        bool ok = ourToken.transferFrom(bob, alice, spendAmount);
        assertTrue(ok);

        assertEq(ourToken.allowance(bob, alice), approveAmount - spendAmount);
    }

    function _findInitialHolderFromMint(
        Vm.Log[] memory entries
    ) internal pure returns (address holder) {
        for (uint256 i = 0; i < entries.length; i++) {
            Vm.Log memory entry = entries[i];
            if (entry.topics.length != 3) continue;
            if (entry.topics[0] != TRANSFER_EVENT_SIG) continue;

            address from = address(uint160(uint256(entry.topics[1])));
            address to = address(uint160(uint256(entry.topics[2])));
            uint256 value = abi.decode(entry.data, (uint256));

            if (from == address(0) && value == INITIAL_SUPPLY) {
                return to;
            }
        }
        revert("Mint event not found");
    }
}
