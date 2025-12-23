// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";

/// @title NFT Marketplace (Settlement Layer)
/// @notice Minimal on-chain settlement contract for listing and buying ERC721 / ERC1155 NFTs with ETH.
/// @dev Follows the PRD in README.md: minimal responsibilities, supports ERC721 & ERC1155 via ERC165,
///      uses Checks-Effects-Interactions and a simple nonReentrant guard.
contract NFTMarketplace {
    /// @notice Listing data stored on-chain for each sell intent.
    struct Listing {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 amount; // ERC721: always 1, ERC1155: arbitrary > 0
        uint256 price; // in wei
        bool active; // true if the listing can still be bought
    }

    /// @notice Next listing id to use (starts from 1 for easier off-chain handling).
    uint256 public nextListingId = 0;

    /// @notice Mapping from listing id to Listing data.
    mapping(uint256 => Listing) public listings;

    /// @dev Simple reentrancy guard flag.
    bool private _entered;

    /// @notice Emitted when a new listing is created.
    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nft,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    /// @notice Emitted when a listing is cancelled by the seller.
    event Cancelled(uint256 indexed listingId);

    /// @notice Emitted when a listing is successfully bought.
    event Sold(uint256 indexed listingId, address indexed buyer);

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        require(!_entered, "ReentrancyGuard");
        _entered = true;
    }

    function _nonReentrantAfter() internal {
        _entered = false;
    }

    // ========= External API =========

    /// @notice List an NFT for sale.
    /// @param nft Address of the NFT contract (ERC721 or ERC1155).
    /// @param tokenId Token id to sell.
    /// @param amount Amount to sell (ERC721 must be 1, ERC1155 > 0).
    /// @param price Sale price in wei.
    /// @return listingId Newly created listing id.
    function list(
        address nft,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external returns (uint256 listingId) {
        require(price > 0, "Price must be > 0");
        require(amount > 0, "Amount must be > 0");

        (bool isERC721, bool isERC1155) = _detectStandard(nft);
        require(isERC721 || isERC1155, "Unsupported NFT standard");

        if (isERC721) {
            require(amount == 1, "ERC721 amount must be 1");

            IERC721 token = IERC721(nft);

            // Ownership check
            require(token.ownerOf(tokenId) == msg.sender, "Not token owner");

            // Approval check: either approved for this token or approved for all
            require(
                token.getApproved(tokenId) == address(this)
                    || token.isApprovedForAll(msg.sender, address(this)),
                "Marketplace not approved"
            );
        } else {
            // ERC1155 path
            IERC1155 token = IERC1155(nft);

            // Balance & approval checks
            require(token.balanceOf(msg.sender, tokenId) >= amount, "Insufficient balance");
            require(token.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");
        }

        listingId = ++nextListingId;

        listings[listingId] = Listing({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            amount: amount,
            price: price,
            active: true
        });

        emit Listed(listingId, msg.sender, nft, tokenId, amount, price);
    }

    /// @notice Cancel an active listing.
    /// @param listingId Id of the listing to cancel.
    function cancel(uint256 listingId) external {
        Listing storage listing = listings[listingId];

        require(listing.seller != address(0), "Listing does not exist");
        require(listing.active, "Listing not active");
        require(msg.sender == listing.seller, "Only seller");

        listing.active = false;

        emit Cancelled(listingId);
    }

    /// @notice Buy an active listing by paying exact ETH.
    /// @param listingId Id of the listing to buy.
    function buy(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];

        require(listing.seller != address(0), "Listing does not exist");
        require(listing.active, "Listing not active");
        require(msg.value == listing.price, "Incorrect ETH amount");

        // Effects: close the listing before any external calls (CEI pattern)
        listing.active = false;

        (bool isERC721, bool isERC1155) = _detectStandard(listing.nft);
        require(isERC721 || isERC1155, "Unsupported NFT standard");

        // Interactions: transfer NFT then ETH
        if (isERC721) {
            require(listing.amount == 1, "ERC721 amount must be 1");
            IERC721(listing.nft).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);
        } else {
            IERC1155(listing.nft).safeTransferFrom(
                listing.seller,
                msg.sender,
                listing.tokenId,
                listing.amount,
                ""
            );
        }

        (bool sent, ) = listing.seller.call{value: msg.value}("");
        require(sent, "ETH transfer failed");

        emit Sold(listingId, msg.sender);
    }

    // ========= Internal helpers =========

    /// @dev Detects whether `nft` contract supports ERC721 and/or ERC1155 via ERC165.
    ///      Uses try/catch so that non-ERC165 contracts simply return false.
    function _detectStandard(address nft) internal view returns (bool isERC721, bool isERC1155) {
        try IERC165(nft).supportsInterface(type(IERC721).interfaceId) returns (bool supports721) {
            isERC721 = supports721;
        } catch {
            isERC721 = false;
        }

        try IERC165(nft).supportsInterface(type(IERC1155).interfaceId) returns (bool supports1155) {
            isERC1155 = supports1155;
        } catch {
            isERC1155 = false;
        }
    }
}
