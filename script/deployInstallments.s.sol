// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {Installments} from "../src/installments.sol";

contract DeployInstallments is Script {
    address immutable i_PAYER;
    address immutable i_CONTRACTOR;
    address immutable i_TOKEN;
    uint256 immutable i_TOTAL;
    uint128 immutable i_END_TIME;
    uint64 immutable i_INTERVAL;

    constructor(
        address _payer,
        address _contractor,
        address _token,
        uint256 _total,
        uint128 _endTime,
        uint64 _interval
    ) {
        i_PAYER = _payer;
        i_CONTRACTOR = _contractor;
        i_TOKEN = _token;
        i_TOTAL = _total;
        i_END_TIME = _endTime;
        i_INTERVAL = _interval;
    }

    function run() external returns (Installments) {
        vm.startBroadcast();
        Installments installments = new Installments(
            i_PAYER,
            i_CONTRACTOR,
            i_TOKEN,
            i_TOTAL,
            i_END_TIME,
            i_INTERVAL
        );
        vm.stopBroadcast();
        return installments;
    }
}
