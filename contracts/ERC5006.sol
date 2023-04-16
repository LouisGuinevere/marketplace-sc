// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IERC5006.sol";

contract ERC5006 is ERC1155, ERC1155Receiver, IERC5006 {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Frozens {
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
    }

    mapping(uint256 => mapping(address => LeasingSession[])) internal _leased;
    mapping(uint256 => mapping(address => Frozens[])) internal _frozens;
    mapping(uint256 => RentingSession) internal _rents;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet))
        private _userRentingSessionIds;
    uint256 _curRentingSessionId = 0;

    constructor() ERC1155("ipfs://arandomipfslink") {}

    function isOwnerOrApproved(address owner) public view returns (bool) {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "only owner or approved"
        );
        return true;
    }

    function userRecordOf(
        uint256 rentId
    ) external view override returns (RentingSession memory) {
        return _rents[rentId];
    }

    function usableBalanceOf(
        address account,
        uint256 tokenId,
        uint256 time
    ) public view override returns (uint256) {
        uint256 amount = 0;
        amount += balanceOf(account, tokenId);
        uint256[] memory recordIds = _userRentingSessionIds[tokenId][account]
            .values();
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (
                time >= _rents[recordIds[i]].startDate &&
                time <= _rents[recordIds[i]].endDate
            ) {
                amount += _rents[recordIds[i]].amount;
            }
        }
        for (uint256 i = 0; i < _frozens[tokenId][account].length; i++) {
            if (
                time >= _frozens[tokenId][account][i].startDate &&
                time <= _frozens[tokenId][account][i].endDate
            ) {
                amount -= _frozens[tokenId][account][i].amount;
            }
        }
        return amount;
    }

    function leasedBalanceOf(
        address account,
        uint256 tokenId,
        uint256 time
    ) public view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < _leased[tokenId][account].length; i++) {
            if (
                time >= _leased[tokenId][account][i].startDate &&
                time <= _leased[tokenId][account][i].endDate
            ) {
                amount += _leased[tokenId][account][i].amount;
            }
        }
        return amount;
    }

    function frozenBalanceOf(
        address account,
        uint256 tokenId,
        uint256 time
    ) external view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < _frozens[tokenId][account].length; i++) {
            if (
                time >= _frozens[tokenId][account][i].startDate &&
                time <= _frozens[tokenId][account][i].endDate
            ) {
                amount += _frozens[tokenId][account][i].amount;
            }
        }
        return amount;
    }

    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    ) public override returns (uint256) {
        require(isOwnerOrApproved(owner));
        require(user != address(0), "user cannot be the zero address");
        require(amount > 0, "amount must be greater than 0");
        require(
            endDate > block.timestamp,
            "expiry must after the block timestamp"
        );
        require(startDate < endDate, "start date must be before end date");
        _frozens[tokenId][owner].push(Frozens(amount, startDate, endDate));
        _curRentingSessionId++;
        _rents[_curRentingSessionId] = RentingSession(
            tokenId,
            owner,
            amount,
            user,
            startDate,
            endDate
        );
        _userRentingSessionIds[tokenId][user].add(_curRentingSessionId);
        emit CreateUserRecord(
            _curRentingSessionId,
            tokenId,
            amount,
            owner,
            user,
            startDate,
            endDate
        );
        return _curRentingSessionId;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Receiver, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC5006).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
