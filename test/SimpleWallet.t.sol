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
        uint256 transactionHistoryLengthBefore = wallet.getTransactionHistory().length;

        vm.prank(owner);

        wallet.transferFromContract(payable(bob), ethersTotransferFromContract);
        uint256 balanceOfBobAfter = bob.balance;
        uint256 balanceOfContractAfter = wallet.getContractBalanceInWei();
        uint256 transactionHistoryLengthAfter = wallet.getTransactionHistory().length;

        
        assertEq(balanceOfBobAfter - balanceOfBobBefore, ethersTotransferFromContract);
        assertEq(balanceOfContractbefore - balanceOfContractAfter, ethersTotransferFromContract);
        
        assertEq(transactionHistoryLengthAfter - transactionHistoryLengthBefore, 1);
    }


}
