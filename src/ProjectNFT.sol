// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC721, IERC721Metadata} from "forge-std/interfaces/IERC721.sol";

/// @title ProjectNFT
/// @notice Minimal ERC721 implementation with minting, used together with NFTMarketplace
///         to打通 NFT 铸造 -> 上架 -> 购买的完整链路。
/// @dev 不做复杂逻辑，只支持单个 collection，Owner 有权限铸造。
contract ProjectNFT is IERC721, IERC721Metadata {
    // ============ ERC721 Storage ============

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ERC721Metadata
    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;

    // Minting
    uint256 public nextTokenId;

    // ============ Constructor ============

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ============ ERC165 ============

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // ============ ERC721 Metadata ============

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_owners[tokenId] != address(0), "nonexistent token");
        return _tokenURIs[tokenId];
    }

    // ============ ERC721 Core ============

    function balanceOf(address owner_) external view override returns (uint256) {
        require(owner_ != address(0), "zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "nonexistent token");
        return owner_;
    }

    function approve(address to, uint256 tokenId) external payable override {
        address owner_ = ownerOf(tokenId);
        require(
            msg.sender == owner_ || isApprovedForAll(owner_, msg.sender),
            "not owner"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
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

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner_][operator];
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
        // 简化实现：不做 onERC721Received 回调检查，假设接收方是 EOA 或能处理 ERC721。
        transferFrom(from, to, tokenId);
    }

    // ============ Minting ============

    /// @notice 铸造新的 NFT，指定接收地址和元数据 URI（通常指向 IPFS）。
    /// @dev 完全开放接口，任何地址都可以调用，业务侧可自行做风控。
    function mint(address to, string calldata uri)
        external
        returns (uint256 tokenId)
    {
        require(to != address(0), "mint to zero");

        tokenId = ++nextTokenId;
        require(_owners[tokenId] == address(0), "already minted");

        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);
    }

    // ============ Internal helpers ============

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner_ = _owners[tokenId];
        return (
            spender == owner_ ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner_][spender]
        );
    }
}
