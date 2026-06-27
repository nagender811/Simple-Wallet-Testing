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

   