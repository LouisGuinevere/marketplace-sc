// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5006 {
    struct Amount {
        uint256 amount;
        uint256 time;
    }

    struct LeasingSession {
        bytes32 leaseId;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
    }

    struct RentingSession {
        uint256 tokenId;
        address owner;
        uint256 amount;
        address user;
        uint256 startDate;
        uint256 endDate;
    }
    /**
     * @dev Emitted when permission (for `user` to use `amount` of `tokenId` token owned by `owner`
     * until `expiry`) is given.
     */
    event CreateUserRecord(
        uint256 recordId,
        uint256 tokenId,
        uint256 amount,
        address owner,
        address user,
        uint256 startDate,
        uint256 endDate
    );
    /**
     * @dev Emitted when record of `recordId` is deleted.
     */
    event DeleteUserRecord(uint256 recordId);

    function leasedBalanceOf(
        address account,
        uint256 tokenId,
        uint256 time
    ) external view returns (uint256);

    /**
     * @dev Returns the usable amount of `tokenId` tokens  by `account`.
     */
    function usableBalanceOf(
        address account,
        uint256 tokenId,
        uint256 time
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of frozen tokens of token type `id` by `account`.
     */
    function frozenBalanceOf(
        address account,
        uint256 tokenId,
        uint256 time
    ) external view returns (uint256);

    /**
     * @dev Returns the `UserRecord` of `recordId`.
     */
    function userRecordOf(
        uint256 recordId
    ) external view returns (RentingSession memory);

    /**
     * @dev Gives permission to `user` to use `amount` of `tokenId` token owned by `owner` until `expiry`.
     *
     * Emits a {CreateUserRecord} event.
     *
     * Requirements:
     *
     * - If the caller is not `owner`, it must be have been approved to spend ``owner``'s tokens
     * via {setApprovalForAll}.
     * - `owner` must have a balance of tokens of type `id` of at least `amount`.
     * - `user` cannot be the zero address.
     * - `amount` must be greater than 0.
     * - `expiry` must after the block timestamp.
     */
    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    ) external returns (uint256);

    // /**
    //  * @dev Atomically delete `record` of `recordId` by the caller.
    //  *
    //  * Emits a {DeleteUserRecord} event.
    //  *
    //  * Requirements:
    //  *
    //  * - the caller must have allowance.
    //  */
    // function deleteUserRecord(uint256 recordId) external;
}
