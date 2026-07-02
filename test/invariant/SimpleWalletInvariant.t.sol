// SPDX-License-Identifier: UNLICENSED
pragma solidity  ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {SimpleWallet} from "../../src/SimpleWallet.sol";
import {SimpleWalletHandler} from "./SimpleWalletHandler.sol";

contract SimpleWalletInvariant is StdInvariant, Test {
    SimpleWallet wallet;
    SimpleWalletHandler handler;

    function setUp() public {
        wallet = new SimpleWallet();
        handler = new SimpleWalletHandler(wallet);

        bytes4[] memory selectors = new bytes4[](4);

        selectors[0] = SimpleWalletHandler.deposit.selector;
        selectors[1] = SimpleWalletHandler.transferToOwner.selector;
        selectors[2] = SimpleWalletHandler.sendDirectly.selector;
        selectors[3] = SimpleWalletHandler.toggleEmergency.selector;

        targetContract(address(handler));
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
    }

    function invariant_TransactionHistoryNeverShrinks() public {
        uint256 currentLength = wallet.getTransactionHistory().length;

        assertGe(currentLength, handler.previousLength);
    }
}
