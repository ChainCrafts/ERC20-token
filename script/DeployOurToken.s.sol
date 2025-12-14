// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {OurToken} from "../src/OurToken.sol";

contract DeployOurToken is Script {
    uint256 constant initialSupply = 1000000e18;

    function run() external returns(OurToken){
        vm.startBroadcast();
        OurToken ot = new OurToken(initialSupply);
        vm.stopBroadcast();
        return ot;
    }
}
