// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {Bridge} from "../src/Bridge.sol";

contract DeployLocal is Script {
    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        address relayer = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

        vm.startBroadcast(deployerPrivateKey);

        MyToken token1 = new MyToken(deployer);
        Bridge bridge1 = new Bridge(address(token1), relayer, deployer);

        MyToken token2 = new MyToken(deployer);
        Bridge bridge2 = new Bridge(address(token2), relayer, deployer);
        console.log("Token1:", address(token1));
        console.log("Bridge1:", address(bridge1));
        console.log("Token2:", address(token2));
        console.log("Bridge2:", address(bridge2));
        console.log("Deployer:", deployer);
        console.log("Relayer:", relayer);

        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);
        token1.transferOwnership(address(bridge1));
        console.log("Transferred token1 ownership to bridge1");

        token2.transferOwnership(address(bridge2));
        console.log("Transferred token2 ownership to bridge2");

        vm.stopBroadcast();
    }
}
