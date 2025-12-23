// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ProjectNFT} from "../src/ProjectNFT.sol";
import {Project1155} from "../src/Project1155.sol";

/// @notice One-click deploy script for ProjectNFT (ERC721) and Project1155 (ERC1155).
/// @dev 使用 forge script 搭配 --rpc-url 和 --private-key，在同一条链上一键部署两个合约。
contract DeployProjectTokens is Script {
    function run() external {
        // 私钥通过命令行参数提供（--private-key），这里不读取 env。
        vm.startBroadcast();

        // 部署 ERC721 合约
        ProjectNFT erc721 = new ProjectNFT("Project NFT", "PNFT");
        console2.log("ProjectNFT (ERC721) deployed at:", address(erc721));

        // 部署 ERC1155 合约
        Project1155 erc1155 = new Project1155();
        console2.log("Project1155 (ERC1155) deployed at:", address(erc1155));

        vm.stopBroadcast();
    }
}

