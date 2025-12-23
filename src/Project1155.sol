// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";

/// @title Project1155
/// @notice Minimal ERC1155 implementation with minting, used together with NFTMarketplace
///         打通 ERC1155 NFT 铸造 -> 上架 -> 购买的完整链路。
/// @dev 单 Collection，多 tokenId、多数量；Owner 有权限铸造。
contract Project1155 is IERC1155 {
    // balances[id][owner] = amount
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // 元数据：每个 id 对应一个 URI（通常是 IPFS 链接）
    mapping(uint256 => string) private _uris;

    constructor() {}

    // ========= ERC165 =========

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // ========= ERC1155 Core =========

    function balanceOf(address account, uint256 id)
        external
        view
        override
        returns (uint256)
    {
        require(account != address(0), "zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory balances)
    {
        require(accounts.length == ids.length, "length mismatch");
        balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = _balances[ids[i]][accounts[i]];
        }
    }

    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata /* data */
    ) external override {
        require(to != address(0), "transfer to zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "not approved"
        );

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= value, "insufficient balance");

        _balances[id][from] = fromBalance - value;
        _balances[id][to] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata /* data */
    ) external override {
        require(to != address(0), "transfer to zero");
        require(ids.length == values.length, "length mismatch");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "not approved"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= value, "insufficient balance");
            _balances[id][from] = fromBalance - value;
            _balances[id][to] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    // ========= Metadata =========

    /// @notice 返回某个 tokenId 对应的元数据 URI（例如 IPFS 链接）。
    function uri(uint256 id) external view returns (string memory) {
        return _uris[id];
    }

    // ========= Minting =========

    /// @notice 铸造 ERC1155 代币到指定地址。
    /// @param to 接收地址
    /// @param id 代币类型 ID
    /// @param amount 铸造数量
    /// @param newUri 元数据 URI，当首次为该 id 铸造时设置（后续可传空字符串表示不修改）
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string calldata newUri
    ) external {
        require(to != address(0), "mint to zero");
        require(amount > 0, "amount zero");

        _balances[id][to] += amount;

        if (bytes(newUri).length > 0 && bytes(_uris[id]).length == 0) {
            _uris[id] = newUri;
            emit URI(newUri, id);
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

}
