// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";

/// @notice Minimal ERC1155 implementation for testing the marketplace.
contract MockERC1155 is IERC1155 {
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner, uint256 id)
        external
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "zero address");
        return _balances[id][owner];
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "length mismatch");
        balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = _balances[ids[i]][owners[i]];
        }
    }

    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
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

    // ====== Test helpers ======

    function mint(address to, uint256 id, uint256 value) external {
        require(to != address(0), "mint to zero");
        _balances[id][to] += value;
        emit TransferSingle(msg.sender, address(0), to, id, value);
    }
}

