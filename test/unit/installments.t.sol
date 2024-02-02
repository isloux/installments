// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Installments} from "../../src/installments.sol";
import {DeployInstallments} from "../../script/DeployInstallments.s.sol";
import {BaseSetup, console} from "./baseSetup.t.sol";

contract InstallmentsTest is BaseSetup {
    Installments installments;
    uint256 constant AMOUNT = 700 ether;
    uint256 constant INITIAL_SUPPLY = 1000 ether;
    uint256 constant TOTAL_PAID = 100 ether;
    uint128 immutable END_TIME = uint128(block.timestamp) + 180 days;
    uint64 constant INTERVAL = 2635200; // 30.5 days
    uint128 immutable START_TIME = uint128(block.timestamp);
    uint64 constant NUMBER_OF_INSTALLMENTS = 6;

    constructor() BaseSetup(INITIAL_SUPPLY) {}

    function setUp() external {
        DeployInstallments deployInstallments = new DeployInstallments(
            alice,
            bob,
            address(this),
            TOTAL_PAID,
            END_TIME,
            INTERVAL
        );
        installments = deployInstallments.run();
    }

    function testToken() public {
        assertEq(installments.whichToken(), address(this));
    }

    function testReceive() public {
        vm.prank(alice);
        this.transfer(address(installments), AMOUNT);
        assertEq(this.balanceOf(address(installments)), AMOUNT);
    }

    function testAgree() public {
        vm.prank(bob);
        installments.agree();
        vm.prank(alice);
        installments.agree();
        assertEq(installments.getAgreement(), 2);
    }

    function testNotAllAgree() public {
        vm.prank(alice);
        installments.agree();
        assertEq(installments.getAgreement(), 1);
    }

    function testNotParty() public {
        vm.expectRevert();
        vm.prank(mallory);
        installments.agree();
    }

    function testGetNInstallments() public {
        uint64 N = uint64(END_TIME - START_TIME) / INTERVAL + 1;
        assertEq(N, installments.getNInstallments());
    }

    modifier funded() {
        vm.prank(alice);
        this.transfer(address(installments), AMOUNT);
        _;
    }

    function testPayerPaid() public funded {
        assertEq(this.balanceOf(alice), INITIAL_SUPPLY - AMOUNT);
        assertEq(this.balanceOf(address(installments)), AMOUNT);
    }

    function testWithdraw() public funded {
        vm.prank(alice);
        installments.withdraw();
        assertEq(this.balanceOf(alice), INITIAL_SUPPLY);
        assertEq(this.balanceOf(address(installments)), 0);
    }

    function testNInstallments() public {
        assertEq(installments.getNInstallments(), NUMBER_OF_INSTALLMENTS);
    }

    modifier contractAgreed() {
        vm.prank(bob);
        installments.agree();
        vm.prank(alice);
        installments.agree();
        _;
    }

    function testFirstInstallment() public funded contractAgreed {
        vm.warp(block.timestamp + 31 days);
        installments.payInstallment();
        assertEq(installments.getCurrentInstallment(), 1);
    }

    function testTooEarlyPaymentAttempt() public funded contractAgreed {
        vm.warp(block.timestamp + 28 days);
        vm.expectRevert();
        installments.payInstallment();
    }
}
