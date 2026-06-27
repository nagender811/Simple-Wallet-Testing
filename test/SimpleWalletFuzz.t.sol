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

}
