// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {SimpleWallet} from "../../src/SimpleWallet.sol";

contract SimpleWalletHandler is Test {
    SimpleWallet wallet;

    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 previousLength;

    constructor(SimpleWallet _wallet) {
        wallet = _wallet;
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, 1, 1000 ether);

        vm.deal(alice, amount);

        vm.prank(alice);
        wallet.depositToContract{value: amount}(block.timestamp - 1);

        previousLength++;
    }

    function transferToOwner(uint256 amount) public {
        amount = bound(amount, 1, 1000 ether);

        vm.deal(alice, amount);
        vm.prank(alice);

        wallet.sendFundsToOwner{value: amount}();

        previousLength++;
    }

    function sendDirectly(address amount) public {
        amount = bound(amount, 1, 1000 ether);

        vm.deal(alice, amount);
        vm.prank(alice);

        wallet.transferDirectlyToUser{value: amount}(payable(bob));

        previousLength++;
    }

    function toggleEmergency() public {
        wallet.toggleEmergencyMode();
    }
}
