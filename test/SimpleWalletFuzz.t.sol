// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

contract SimpleWalletFuzzTest is Test {
    SimpleWallet wallet;

    address owner;
    address alice;
    address bob;

    error StartTimeNotReached();

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        wallet = new SimpleWallet();
    }

    function testFuzz_DepositIncreasesContractBalance(
        uint256 depositAmount
    ) public {
        uint256 testStartTime = block.timestamp - 1;
        depositAmount = bound(depositAmount, 0, 1000 ether);
        uint256 balanceOfContractBefore = wallet.getContractBalanceInWei();
        vm.assume(depositAmount != 0);
        vm.deal(alice, depositAmount);

        vm.prank(alice);
        wallet.depositToContract{value: depositAmount}(testStartTime);

        uint256 balanceOfContractAfter = wallet.getContractBalanceInWei();

        assertEq(
            balanceOfContractAfter,
            balanceOfContractBefore + depositAmount
        );
    }

    function testFuzz_TransferFromContractUpdatesBalances(
        uint256 depositAmount,
        uint256 amount
    ) public {
        uint256 testStartTime = block.timestamp - 1;
        depositAmount = bound(depositAmount, 1, 1000 ether);
        vm.deal(alice, depositAmount);

        vm.prank(alice);
        wallet.depositToContract{value: depositAmount}(testStartTime);

        uint256 balanceOfBobBefore = bob.balance;

        amount = bound(amount, 1, depositAmount);

        wallet.transferFromContract(payable(bob), amount);

        uint256 balanceOfContractAfter = wallet.getContractBalanceInWei();
        uint256 balanceOfBobAfter = bob.balance;

        assertEq(balanceOfContractAfter, depositAmount - amount);

        assertEq(balanceOfBobAfter, balanceOfBobBefore + amount);
    }

    function testFuzz_OwnershipTransferForAnyValidAddress(
        address newOwner
    ) public {
        newOwner = address(
            uint160(bound(uint160(newOwner), 1, type(uint160).max))
        );

        wallet.changeOwner(newOwner);

        assertEq(wallet.walletOwner(), newOwner);
    }

    function testFuzz_TransferDirectlyToUserSendsCorrectAmount(
        uint256 amount
    ) public {
        uint256 balanceOfBobBefore = bob.balance;
        vm.assume(amount > 0);
        vm.deal(alice, amount);
        vm.prank(alice);

        wallet.transferDirectlyToUser{value: amount}(payable(bob));

        uint256 balanceOfBobAfter = bob.balance;

        assertEq(balanceOfBobAfter - balanceOfBobBefore, amount);
    }
    function testFuzz_DepositStartTimeBehavesCorrectly(
        uint256 testStartTime
    ) public {
        vm.assume(testStartTime >= block.timestamp);
        vm.deal(alice, 1 ether);
        vm.prank(alice);

        vm.expectRevert(StartTimeNotReached.selector);
        wallet.depositToContract{value: 1 ether}(testStartTime);
    }
}
