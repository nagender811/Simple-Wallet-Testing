// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

contract SimpleWalletTest is Test {
    SimpleWallet wallet;

    address owner;
    address alice;
    address bob;

    error Unauthorized();
    error EmergencyActive();
     error SuspiciousActivityDetected();

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        wallet = new SimpleWallet();
    }

    function testVerifyDeployerIsOwner() public view {
        assertEq(wallet.walletOwner(), owner);
    }

    function test_VerifyUserCanDepositEther() public {
        uint testStartTime = block.timestamp - 1;
        vm.prank(alice);
        vm.deal(alice, 10 ether);

        wallet.depositToContract{value: 1 ether}(testStartTime);

        assertEq(wallet.getContractBalanceInWei(), 1 ether);
        assertEq(wallet.getTransactionHistory().length, 1);
    }

    function testNonOwnerCannotTransferFromContract() public {
        uint256 ethersTotransferFromContract = 1 ether;
        vm.prank(alice);
        vm.expectRevert(abi.encode(Unauthorized.selector));
        wallet.transferFromContract(payable(bob), ethersTotransferFromContract);
    }

    function testOwnerCanTransferFromContract() public {
        uint256 ethersTotransferFromContract = 1 ether;
        uint256 testStartTime = block.timestamp - 1;
        vm.deal(alice, 5 ether);
        vm.prank(alice);

        wallet.depositToContract{value: 5 ether}(testStartTime);
        uint256 balanceOfBobBefore = bob.balance;
        uint256 balanceOfContractbefore = wallet.getContractBalanceInWei();
        uint256 transactionHistoryLengthBefore = wallet
            .getTransactionHistory()
            .length;

        vm.prank(owner);

        wallet.transferFromContract(payable(bob), ethersTotransferFromContract);

        uint256 balanceOfBobAfter = bob.balance;
        uint256 balanceOfContractAfter = wallet.getContractBalanceInWei();
        uint256 transactionHistoryLengthAfter = wallet
            .getTransactionHistory()
            .length;

        assertEq(
            balanceOfBobAfter - balanceOfBobBefore,
            ethersTotransferFromContract
        );
        assertEq(
            balanceOfContractbefore - balanceOfContractAfter,
            ethersTotransferFromContract
        );

        assertEq(
            transactionHistoryLengthAfter - transactionHistoryLengthBefore,
            1
        );
    }

    function testEmergencyModeBlocksNormalOperations() public {
        uint256 testStartTime = block.timestamp - 1;
        vm.prank(owner);
        wallet.toggleEmergencyMode();

        vm.deal(alice, 1 ether);
        vm.prank(alice);

        vm.expectRevert(EmergencyActive.selector);
        wallet.depositToContract{value: 1 ether}(testStartTime);
    }

    function testEmergencyWithdrawalTransfersAllFundsToOwner() public {
        uint256 testStartTime = block.timestamp - 1;
        uint256 balanceOfOwnerBefore = owner.balance;
        vm.deal(alice, 10 ether);
        vm.prank(alice);

        wallet.depositToContract{value: 5 ether}(testStartTime);

        uint256 contractBalanceBeforeWithdrawal = wallet
            .getContractBalanceInWei();

        vm.prank(owner);
        wallet.toggleEmergencyMode();
        wallet.emergencyWithdrawal();

        uint256 balanceOfOwnerAfter = owner.balance;

        uint256 contractBalanceAfterWithdrawal = wallet
            .getContractBalanceInWei();

        assertEq(contractBalanceAfterWithdrawal, 0);
        assertEq(
            balanceOfOwnerAfter - balanceOfOwnerBefore,
            contractBalanceBeforeWithdrawal
        );
    }

    function testTransactionsAreStoredCorrectly() public {
        uint256 ethersTotransferFromContract = 1 ether;
        uint256 testStartTime = block.timestamp - 1;
        vm.deal(alice, 5 ether);
        vm.prank(alice);

        wallet.depositToContract{value: 3 ether}(testStartTime);

        wallet.transferFromContract(payable(bob), ethersTotransferFromContract);

        SimpleWallet.Transaction[] memory transactions = wallet
            .getTransactionHistory();

        assertEq(transactions.length, 2);
        assertEq(transactions[0].sender, alice);
        assertEq(transactions[0].receiver, address(wallet));
        assertEq(transactions[0].amount, 3 ether);

        assertEq(transactions[1].sender, address(wallet));
        assertEq(transactions[1].receiver, bob);
        assertEq(transactions[1].amount, ethersTotransferFromContract);
    }

    function testSuspiciousUserDetection() public {
        uint256 testStartTime = block.timestamp - 1;

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(bob);

            (bool success, ) = address(wallet).call(
                abi.encodeWithSignature("wallet.suspicious()")
            );

            assertTrue(success);
        }

        vm.deal(bob, 1 ether);

        vm.prank(bob);
        vm.expectRevert(SuspiciousActivityDetected.selector);

        wallet.depositToContract{value: 1 ether}(testStartTime);
    }

    receive() external payable {}
}
