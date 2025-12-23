// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {
    IERC721,
    IERC721TokenReceiver
} from "forge-std/interfaces/IERC721.sol";

/// @notice Minimal ERC721 implementation for testing the marketplace.
contract MockERC721 is IERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) external payable override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "not owner"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        require(_owners[tokenId] != address(0), "nonexistent token");
        return _tokenApprovals[tokenId];
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

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved");
        require(ownerOf(tokenId) == from, "wrong from");
        require(to != address(0), "transfer to zero");

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        external
        payable
        override
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory /* data */
    ) public payable override {
        // For tests we treat safe transfer as a normal transfer (EOA recipients only).
        transferFrom(from, to, tokenId);
    }

    // ====== Test helpers ======

    function mint(address to, uint256 tokenId) external {
        require(to != address(0), "mint to zero");
        require(_owners[tokenId] == address(0), "already minted");
        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = _owners[tokenId];
        return (
            spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]
        );
    }
}

