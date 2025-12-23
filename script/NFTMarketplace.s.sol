// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract DeployNFTMarketplace is Script {
    function run() external {
        // 私钥不在脚本里读取，由 forge 命令行参数提供
        // 例如：--private-key 或 --sender 等
        vm.startBroadcast();

        // NFTMarketplace 没有构造参数，直接 new 即可
        NFTMarketplace marketplace = new NFTMarketplace();

        vm.stopBroadcast();

        // 方便在 script 日志里看到部署地址
        console2.log("NFTMarketplace deployed at:", address(marketplace));
    }
}
