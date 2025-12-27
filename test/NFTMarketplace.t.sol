// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC1155} from "./mocks/MockERC1155.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace marketplace;
    MockERC721 erc721;
    MockERC1155 erc1155;

    address seller = address(1);
    address buyer = address(2);

    // Re-declare events to use expectEmit
    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nft,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );
    event Cancelled(uint256 indexed listingId);
    event Sold(uint256 indexed listingId, address indexed buyer);

    function setUp() public {
        marketplace = new NFTMarketplace();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();

        erc721.mint(seller, 1);
        erc1155.mint(seller, 1, 100);

        vm.deal(buyer, 100 ether);
    }

    function testListERC721Success() public {
        vm.prank(seller);
        erc721.approve(address(marketplace), 1);

        vm.expectEmit(true, true, true, true, address(marketplace));
        emit Listed(1, seller, address(erc721), 1, 1, 1 ether);

        vm.prank(seller);
        uint256 id = marketplace.list(address(erc721), 1, 1, 1 ether);

        assertEq(id, 1);

        (address s, address nft, uint256 tokenId, uint256 amount, uint256 price, bool active) =
            marketplace.listings(id);

        assertEq(s, seller);
        assertEq(nft, address(erc721));
        assertEq(tokenId, 1);
        assertEq(amount, 1);
        assertEq(price, 1 ether);
        assertTrue(active);
    }

    function testListERC721AmountNotOneReverts() public {
        vm.prank(seller);
        erc721.approve(address(marketplace), 1);

        vm.prank(seller);
        vm.expectRevert(bytes("ERC721 amount must be 1"));
        marketplace.list(address(erc721), 1, 2, 1 ether);
    }

    function testListERC1155Success() public {
        vm.prank(seller);
        erc1155.setApprovalForAll(address(marketplace), true);

        vm.prank(seller);
        uint256 id = marketplace.list(address(erc1155), 1, 10, 2 ether);

        (address s, address nft, uint256 tokenId, uint256 amount, uint256 price, bool active) =
            marketplace.listings(id);

        assertEq(s, seller);
        assertEq(nft, address(erc1155));
        assertEq(tokenId, 1);
        assertEq(amount, 10);
        assertEq(price, 2 ether);
        assertTrue(active);
    }

    function testListPriceZeroReverts() public {
        vm.prank(seller);
        erc721.approve(address(marketplace), 1);

        vm.prank(seller);
        vm.expectRevert(bytes("Price must be > 0"));
        marketplace.list(address(erc721), 1, 1, 0);
    }

    function testCancelListing() public {
        uint256 id = _createErc721Listing();

        vm.expectEmit(true, false, false, true, address(marketplace));
        emit Cancelled(id);

        vm.prank(seller);
        marketplace.cancel(id);

        (, , , , , bool active) = marketplace.listings(id);
        assertFalse(active);
    }

    function testCancelListingNotSellerReverts() public {
        uint256 id = _createErc721Listing();

        vm.prank(buyer);
        vm.expectRevert(bytes("Only seller"));
        marketplace.cancel(id);
    }

    function testBuyERC721Success() public {
        uint256 id = _createErc721Listing();

        uint256 sellerBefore = seller.balance;
        uint256 buyerBefore = buyer.balance;

        vm.expectEmit(true, true, false, true, address(marketplace));
        emit Sold(id, buyer);

        vm.prank(buyer);
        marketplace.buy{value: 1 ether}(id);

        assertEq(erc721.ownerOf(1), buyer);
        assertEq(seller.balance, sellerBefore + 1 ether);
        assertEq(buyer.balance, buyerBefore - 1 ether);

        (, , , , , bool active) = marketplace.listings(id);
        assertFalse(active);
    }

    function testBuyERC1155Success() public {
        uint256 id = _createErc1155Listing();

        uint256 sellerBefore = seller.balance;
        uint256 buyerBefore = buyer.balance;

        vm.prank(buyer);
        marketplace.buy{value: 2 ether}(id);

        assertEq(erc1155.balanceOf(buyer, 1), 10);
        assertEq(erc1155.balanceOf(seller, 1), 90);
        assertEq(seller.balance, sellerBefore + 2 ether);
        assertEq(buyer.balance, buyerBefore - 2 ether);

        (, , , , , bool active) = marketplace.listings(id);
        assertFalse(active);
    }

    function testBuyWithWrongValueReverts() public {
        uint256 id = _createErc721Listing();

        vm.prank(buyer);
        vm.expectRevert(bytes("Incorrect ETH amount"));
        marketplace.buy{value: 0.5 ether}(id);
    }

    function testBuyInactiveListingReverts() public {
        uint256 id = _createErc721Listing();

        vm.prank(seller);
        marketplace.cancel(id);

        vm.prank(buyer);
        vm.expectRevert(bytes("Listing not active"));
        marketplace.buy{value: 1 ether}(id);
    }

    function testListAmountZeroReverts() public {
        vm.prank(seller);
        erc721.approve(address(marketplace), 1);

        vm.prank(seller);
        vm.expectRevert(bytes("Amount must be > 0"));
        marketplace.list(address(erc721), 1, 0, 1 ether);
    }

    function testListERC721NotOwnerReverts() public {
        // token 1 owned by seller in setUp, but caller is buyer
        vm.prank(buyer);
        vm.expectRevert(bytes("Not token owner"));
        marketplace.list(address(erc721), 1, 1, 1 ether);
    }

    function testListERC721NotApprovedReverts() public {
        // seller owns token but never approves marketplace
        vm.prank(seller);
        vm.expectRevert(bytes("Marketplace not approved"));
        marketplace.list(address(erc721), 1, 1, 1 ether);
    }

    function testListERC721WithApprovalForAllSuccess() public {
        vm.prank(seller);
        erc721.setApprovalForAll(address(marketplace), true);

        vm.prank(seller);
        uint256 id = marketplace.list(address(erc721), 1, 1, 1 ether);

        assertEq(id, 1);
        assertEq(marketplace.nextListingId(), 1);
    }

    function testListERC1155InsufficientBalanceReverts() public {
        vm.prank(seller);
        erc1155.setApprovalForAll(address(marketplace), true);

        vm.prank(seller);
        vm.expectRevert(bytes("Insufficient balance"));
        // seller only has 100 in setUp
        marketplace.list(address(erc1155), 1, 101, 1 ether);
    }

    function testListERC1155NotApprovedReverts() public {
        // seller has balance but never approves marketplace
        vm.prank(seller);
        vm.expectRevert(bytes("Marketplace not approved"));
        marketplace.list(address(erc1155), 1, 10, 1 ether);
    }

    function testListUnsupportedNftReverts() public {
        NonNFT nft = new NonNFT();

        vm.prank(seller);
        vm.expectRevert(bytes("Unsupported NFT standard"));
        marketplace.list(address(nft), 1, 1, 1 ether);
    }

    function testCancelNonexistentListingReverts() public {
        vm.prank(seller);
        vm.expectRevert(bytes("Listing does not exist"));
        marketplace.cancel(999);
    }

    function testCancelAlreadyInactiveListingReverts() public {
        uint256 id = _createErc721Listing();

        vm.prank(seller);
        marketplace.cancel(id);

        vm.prank(seller);
        vm.expectRevert(bytes("Listing not active"));
        marketplace.cancel(id);
    }

    function testBuyNonexistentListingReverts() public {
        vm.prank(buyer);
        vm.expectRevert(bytes("Listing does not exist"));
        marketplace.buy{value: 1 ether}(999);
    }

    function testNextListingIdTracksListingsCount() public {
        assertEq(marketplace.nextListingId(), 0);

        _createErc721Listing();
        assertEq(marketplace.nextListingId(), 1);

        _createErc1155Listing();
        assertEq(marketplace.nextListingId(), 2);
    }

    // ====== Internal helpers ======

    function _createErc721Listing() internal returns (uint256) {
        vm.startPrank(seller);
        erc721.approve(address(marketplace), 1);
        uint256 id = marketplace.list(address(erc721), 1, 1, 1 ether);
        vm.stopPrank();
        return id;
    }

    function _createErc1155Listing() internal returns (uint256) {
        vm.startPrank(seller);
        erc1155.setApprovalForAll(address(marketplace), true);
        uint256 id = marketplace.list(address(erc1155), 1, 10, 2 ether);
        vm.stopPrank();
        return id;
    }
}

contract NonNFT {
}
