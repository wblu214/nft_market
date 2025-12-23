// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

/// @notice Simple deployment script for NFTMarketplace.
/// @dev 部署到 BSC 测试网时，用 forge script 搭配 --rpc-url BSC 测试网节点即可。
contract DeployNFTMarketplace is Script {
    function run() external {
        // 从环境变量读取私钥，例如:
        // export PRIVATE_KEY=0x...
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // NFTMarketplace 没有构造参数，直接 new 即可
        NFTMarketplace marketplace = new NFTMarketplace();

        vm.stopBroadcast();

        // 方便在 script 日志里看到部署地址
        console2.log("NFTMarketplace deployed at:", address(marketplace));
    }
}
