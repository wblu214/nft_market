// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "forge-std/interfaces/IERC165.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {Project1155} from "../src/Project1155.sol";

contract Project1155Test is Test {
    Project1155 token;

    address alice = address(1);
    address bob = address(2);
    address operator = address(3);

    // Re-declare events to use expectEmit
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event URI(string _value, uint256 indexed _id);

    function setUp() public {
        token = new Project1155();
    }

    // ========= supportsInterface =========

    function testSupportsInterface() public {
        assertTrue(token.supportsInterface(type(IERC1155).interfaceId));
        assertTrue(token.supportsInterface(type(IERC165).interfaceId));
        assertFalse(token.supportsInterface(0xffffffff));
    }

    // ========= balanceOf / balanceOfBatch =========

    function testBalanceOfRevertsForZeroAddress() public {
        vm.expectRevert(bytes("zero address"));
        token.balanceOf(address(0), 1);
    }

    function testBalanceOfReturnsMintedAmount() public {
        assertEq(token.balanceOf(alice, 1), 0);

        token.mint(alice, 1, 10, "ipfs://uri1");
        assertEq(token.balanceOf(alice, 1), 10);
    }

    function testBalanceOfBatchReturnsCorrectBalances() public {
        token.mint(alice, 1, 10, "");
        token.mint(bob, 2, 20, "");

        address[] memory accounts = new address[](3);
        uint256[] memory ids = new uint256[](3);

        accounts[0] = alice;
        accounts[1] = bob;
        accounts[2] = alice;

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3; // never minted

        uint256[] memory balances = token.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 10);
        assertEq(balances[1], 20);
        assertEq(balances[2], 0);
    }

    function testBalanceOfBatchLengthMismatchReverts() public {
        address[] memory accounts = new address[](1);
        uint256[] memory ids = new uint256[](2);

        accounts[0] = alice;
        ids[0] = 1;
        ids[1] = 2;

        vm.expectRevert(bytes("length mismatch"));
        token.balanceOfBatch(accounts, ids);
    }

    // ========= setApprovalForAll / isApprovedForAll =========

    function testSetApprovalForAllUpdatesStateAndEmitsEvent() public {
        vm.expectEmit(true, true, false, true, address(token));
        emit ApprovalForAll(alice, operator, true);

        vm.prank(alice);
        token.setApprovalForAll(operator, true);

        assertTrue(token.isApprovedForAll(alice, operator));
    }

    function testIsApprovedForAllFalseByDefault() public view {
        assertFalse(token.isApprovedForAll(alice, operator));
    }

    // ========= safeTransferFrom =========

    function testSafeTransferFromByOwnerSuccess() public {
        token.mint(alice, 1, 100, "");

        vm.expectEmit(true, true, true, true, address(token));
        emit TransferSingle(alice, alice, bob, 1, 40);

        vm.prank(alice);
        token.safeTransferFrom(alice, bob, 1, 40, "");

        assertEq(token.balanceOf(alice, 1), 60);
        assertEq(token.balanceOf(bob, 1), 40);
    }

    function testSafeTransferFromByOperatorSuccess() public {
        token.mint(alice, 1, 50, "");

        vm.prank(alice);
        token.setApprovalForAll(operator, true);

        vm.expectEmit(true, true, true, true, address(token));
        emit TransferSingle(operator, alice, bob, 1, 10);

        vm.prank(operator);
        token.safeTransferFrom(alice, bob, 1, 10, "");

        assertEq(token.balanceOf(alice, 1), 40);
        assertEq(token.balanceOf(bob, 1), 10);
    }

    function testSafeTransferFromToZeroReverts() public {
        token.mint(alice, 1, 10, "");

        vm.prank(alice);
        vm.expectRevert(bytes("transfer to zero"));
        token.safeTransferFrom(alice, address(0), 1, 1, "");
    }

    function testSafeTransferFromNotApprovedReverts() public {
        token.mint(alice, 1, 10, "");

        vm.prank(bob);
        vm.expectRevert(bytes("not approved"));
        token.safeTransferFrom(alice, bob, 1, 1, "");
    }

    function testSafeTransferFromInsufficientBalanceReverts() public {
        token.mint(alice, 1, 5, "");

        vm.prank(alice);
        vm.expectRevert(bytes("insufficient balance"));
        token.safeTransferFrom(alice, bob, 1, 10, "");
    }

    // ========= safeBatchTransferFrom =========

    function testSafeBatchTransferFromByOwnerSuccess() public {
        token.mint(alice, 1, 10, "");
        token.mint(alice, 2, 20, "");

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 4;
        values[1] = 5;

        vm.expectEmit(true, true, true, true, address(token));
        emit TransferBatch(alice, alice, bob, ids, values);

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, bob, ids, values, "");

        uint256[] memory aliceBalances =
            token.balanceOfBatch(_asSingletonArray(alice, alice), _asSingletonArray(1, 2));
        uint256[] memory bobBalances =
            token.balanceOfBatch(_asSingletonArray(bob, bob), _asSingletonArray(1, 2));

        assertEq(aliceBalances[0], 6);
        assertEq(aliceBalances[1], 15);
        assertEq(bobBalances[0], 4);
        assertEq(bobBalances[1], 5);
    }

    function testSafeBatchTransferFromByOperatorSuccess() public {
        token.mint(alice, 1, 10, "");
        token.mint(alice, 2, 10, "");

        vm.prank(alice);
        token.setApprovalForAll(operator, true);

        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        values[0] = 3;
        values[1] = 4;

        vm.expectEmit(true, true, true, true, address(token));
        emit TransferBatch(operator, alice, bob, ids, values);

        vm.prank(operator);
        token.safeBatchTransferFrom(alice, bob, ids, values, "");

        assertEq(token.balanceOf(alice, 1), 7);
        assertEq(token.balanceOf(alice, 2), 6);
        assertEq(token.balanceOf(bob, 1), 3);
        assertEq(token.balanceOf(bob, 2), 4);
    }

    function testSafeBatchTransferFromToZeroReverts() public {
        token.mint(alice, 1, 10, "");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 1;
        values[0] = 1;

        vm.prank(alice);
        vm.expectRevert(bytes("transfer to zero"));
        token.safeBatchTransferFrom(alice, address(0), ids, values, "");
    }

    function testSafeBatchTransferFromLengthMismatchReverts() public {
        token.mint(alice, 1, 10, "");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](2);
        ids[0] = 1;
        values[0] = 1;
        values[1] = 2;

        vm.prank(alice);
        vm.expectRevert(bytes("length mismatch"));
        token.safeBatchTransferFrom(alice, bob, ids, values, "");
    }

    function testSafeBatchTransferFromNotApprovedReverts() public {
        token.mint(alice, 1, 10, "");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 1;
        values[0] = 1;

        vm.prank(bob);
        vm.expectRevert(bytes("not approved"));
        token.safeBatchTransferFrom(alice, bob, ids, values, "");
    }

    function testSafeBatchTransferFromInsufficientBalanceReverts() public {
        token.mint(alice, 1, 5, "");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = 1;
        values[0] = 10;

        vm.prank(alice);
        vm.expectRevert(bytes("insufficient balance"));
        token.safeBatchTransferFrom(alice, bob, ids, values, "");
    }

    // ========= uri / mint =========

    function testMintSetsBalanceUriAndEmitsEvents() public {
        vm.expectEmit(false, false, false, true, address(token));
        emit URI("ipfs://token-1", 1);

        vm.expectEmit(true, true, true, true, address(token));
        emit TransferSingle(address(this), address(0), alice, 1, 10);

        token.mint(alice, 1, 10, "ipfs://token-1");

        assertEq(token.balanceOf(alice, 1), 10);
        assertEq(token.uri(1), "ipfs://token-1");
    }

    function testMintSecondTimeDoesNotOverrideUri() public {
        token.mint(alice, 1, 10, "ipfs://token-1");

        // Even if newUri is non-empty, existing URI should not change
        token.mint(alice, 1, 5, "ipfs://should-be-ignored");

        assertEq(token.balanceOf(alice, 1), 15);
        assertEq(token.uri(1), "ipfs://token-1");
    }

    function testMintToZeroReverts() public {
        vm.expectRevert(bytes("mint to zero"));
        token.mint(address(0), 1, 10, "ipfs://token-1");
    }

    function testMintAmountZeroReverts() public {
        vm.expectRevert(bytes("amount zero"));
        token.mint(alice, 1, 0, "ipfs://token-1");
    }

    function testUriReturnsEmptyStringIfNotSet() public view {
        assertEq(token.uri(1), "");
    }

    // ========= helpers =========

    function _asSingletonArray(address a1, address a2)
        internal
        pure
        returns (address[] memory arr)
    {
        arr = new address[](2);
        arr[0] = a1;
        arr[1] = a2;
    }

    function _asSingletonArray(uint256 i1, uint256 i2)
        internal
        pure
        returns (uint256[] memory arr)
    {
        arr = new uint256[](2);
        arr[0] = i1;
        arr[1] = i2;
    }
}
