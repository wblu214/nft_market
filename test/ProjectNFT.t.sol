// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC721, IERC721Metadata} from "forge-std/interfaces/IERC721.sol";
import {ProjectNFT} from "../src/ProjectNFT.sol";

contract ProjectNFTTest is Test {
    ProjectNFT nft;

    address alice = address(1);
    address bob = address(2);
    address operator = address(3);

    // Re-declare events to use expectEmit
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setUp() public {
        nft = new ProjectNFT("Project NFT", "PNFT");
    }

    // ========= Constructor / Metadata =========

    function testConstructorInitialState() public {
        assertEq(nft.name(), "Project NFT");
        assertEq(nft.symbol(), "PNFT");
        assertEq(nft.nextTokenId(), 0);
    }

    // ========= supportsInterface =========

    function testSupportsInterface() public {
        assertTrue(nft.supportsInterface(type(IERC721).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC165).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC721Metadata).interfaceId));
        assertFalse(nft.supportsInterface(0xffffffff));
    }

    // ========= Minting =========

    function testMintSetsOwnerBalanceUriAndIncrementsId() public {
        vm.expectEmit(true, true, true, true, address(nft));
        emit Transfer(address(0), alice, 1);

        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");
        assertEq(tokenId, 1);
        assertEq(nft.nextTokenId(), 1);

        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.tokenURI(1), "ipfs://nft-1");
    }

    function testMintToZeroReverts() public {
        vm.expectRevert(bytes("mint to zero"));
        nft.mint(address(0), "ipfs://nft-1");
    }

    // ========= balanceOf / ownerOf / tokenURI =========

    function testBalanceOfZeroAddressReverts() public {
        vm.expectRevert(bytes("zero address"));
        nft.balanceOf(address(0));
    }

    function testOwnerOfNonexistentTokenReverts() public {
        vm.expectRevert(bytes("nonexistent token"));
        nft.ownerOf(1);
    }

    function testTokenURINonexistentTokenReverts() public {
        vm.expectRevert(bytes("nonexistent token"));
        nft.tokenURI(1);
    }

    // ========= approve / getApproved / setApprovalForAll / isApprovedForAll =========

    function testApproveAndGetApprovedByOwner() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.expectEmit(true, true, true, true, address(nft));
        emit Approval(alice, bob, tokenId);

        vm.prank(alice);
        nft.approve(bob, tokenId);

        assertEq(nft.getApproved(tokenId), bob);
    }

    function testApproveNotOwnerOrOperatorReverts() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.prank(bob);
        vm.expectRevert(bytes("not owner"));
        nft.approve(operator, tokenId);
    }

    function testGetApprovedNonexistentTokenReverts() public {
        vm.expectRevert(bytes("nonexistent token"));
        nft.getApproved(1);
    }

    function testSetApprovalForAllAndIsApprovedForAll() public {
        vm.expectEmit(true, true, false, true, address(nft));
        emit ApprovalForAll(alice, operator, true);

        vm.prank(alice);
        nft.setApprovalForAll(operator, true);

        assertTrue(nft.isApprovedForAll(alice, operator));
    }

    function testIsApprovedForAllFalseByDefault() public view {
        assertFalse(nft.isApprovedForAll(alice, operator));
    }

    // ========= transferFrom =========

    function testTransferFromByOwnerSuccess() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.expectEmit(true, true, true, true, address(nft));
        emit Transfer(alice, bob, tokenId);

        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function testTransferFromByApprovedAddressSuccess() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.prank(alice);
        nft.approve(operator, tokenId);

        vm.expectEmit(true, true, true, true, address(nft));
        emit Transfer(alice, bob, tokenId);

        vm.prank(operator);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
    }

    function testTransferFromByOperatorSuccess() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.prank(alice);
        nft.setApprovalForAll(operator, true);

        vm.expectEmit(true, true, true, true, address(nft));
        emit Transfer(alice, bob, tokenId);

        vm.prank(operator);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
    }

    function testTransferFromNotApprovedReverts() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.prank(bob);
        vm.expectRevert(bytes("not approved"));
        nft.transferFrom(alice, bob, tokenId);
    }

    function testTransferFromWrongFromReverts() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.prank(alice);
        vm.expectRevert(bytes("wrong from"));
        nft.transferFrom(bob, alice, tokenId);
    }

    function testTransferFromToZeroReverts() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.prank(alice);
        vm.expectRevert(bytes("transfer to zero"));
        nft.transferFrom(alice, address(0), tokenId);
    }

    // ========= safeTransferFrom (overloads) =========

    function testSafeTransferFromWithoutDataByOwner() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.expectEmit(true, true, true, true, address(nft));
        emit Transfer(alice, bob, tokenId);

        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
    }

    function testSafeTransferFromWithDataByOwner() public {
        uint256 tokenId = nft.mint(alice, "ipfs://nft-1");

        vm.expectEmit(true, true, true, true, address(nft));
        emit Transfer(alice, bob, tokenId);

        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, tokenId, "");

        assertEq(nft.ownerOf(tokenId), bob);
    }
}

