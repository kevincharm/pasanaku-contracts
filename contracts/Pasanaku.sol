// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IHub} from "./interfaces/IHub.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Pasanaku
/// @notice A Circles v2 organisation that enables groups to form pasanakus.
contract Pasanaku is IERC1155Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Circles v2 Hub contract
    address public immutable hub;
    /// @notice Circles v2 group
    address public immutable group;
    /// @notice Interval of the round
    uint256 public immutable roundInterval;
    /// @notice Required deposit amount of personal tokens per round
    uint256 public immutable depositAmount;

    /// @notice Current round id
    uint256 public roundId = 1;
    /// @notice Timestamp when the round started
    uint256 public roundStartedAt;
    /// @notice Bitmap of participants who entered the round
    uint256 public entered;
    /// @notice Total pot of the round
    uint256 public pot;
    /// @notice Index of next recipient in the participants list
    uint256 public nextRecipient;

    /// @notice List of participants
    EnumerableSet.AddressSet private participants;

    event Joined(address indexed participant);
    event Left(address indexed participant);
    event Contributed(address indexed participant, uint256 indexed roundId);
    event Finalised(address indexed recipient, uint256 indexed roundId);

    constructor(
        string memory name,
        address hub_,
        address group_,
        uint256 roundInterval_,
        uint256 depositAmount_
    ) {
        hub = hub_;
        require(IHub(hub_).isGroup(group_), "Not a group");
        group = group_;
        roundInterval = roundInterval_;
        depositAmount = depositAmount_;
        IHub(hub).registerOrganization(name, bytes32(0));
    }

    function participantAt(uint256 index) public view returns (address) {
        return participants.at(index);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants.values();
    }

    function positionOf(address participant) public view returns (uint256) {
        return
            participants._inner._positions[
                bytes32(uint256(uint160(participant)))
            ];
    }

    function hasContributed(address participant) public view returns (bool) {
        require(participants.contains(participant), "Not a participant");
        return (entered >> positionOf(participant)) & 1 == 1;
    }

    /// @notice Join the pasanaku
    function join() external {
        require(IHub(hub).isHuman(msg.sender), "Not a human");
        IHub(hub).trust(msg.sender, type(uint96).max);

        require(participants.length() < 256, "Too many participants");
        require(participants.add(msg.sender), "Already joined");

        emit Joined(msg.sender);
    }

    function leave() external {
        require(participants.contains(msg.sender), "Not a participant");
        participants.remove(msg.sender);
        IHub(hub).trust(msg.sender, 0);

        emit Left(msg.sender);
    }

    /// @notice Contribute to the current pasanaku round
    function contribute() external {
        require(participants.contains(msg.sender), "Not a participant");
        uint256 pos = positionOf(msg.sender);
        require((entered >> pos) & 1 == 0, "Already entered");
        entered |= 1 << pos;

        // Transfer personal token of caller to this contract
        IERC1155(hub).safeTransferFrom(
            msg.sender,
            address(this),
            uint256(uint160(msg.sender)),
            depositAmount,
            bytes("")
        );

        // Mint group token with personal tokens
        address[] memory collateralAvatars = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = depositAmount;
        collateralAvatars[0] = msg.sender;
        IHub(hub).groupMint(group, collateralAvatars, amounts, bytes(""));
        pot += depositAmount;

        emit Contributed(msg.sender, roundId);
    }

    /// @notice Finalise the current pasanaku round
    function finalise() external {
        require(
            block.timestamp >= roundStartedAt + roundInterval,
            "Round not ended"
        );
        require(entered != 0, "No participants");

        // Transfer pot to next recipient
        uint256 len = participants.length();
        address recipient = participants.at(nextRecipient);
        IERC1155(hub).safeTransferFrom(
            address(this),
            recipient,
            uint256(uint160(group)),
            pot,
            bytes("")
        );
        // Increment recipient index (wrapround)
        nextRecipient = (nextRecipient + 1) % len;

        // Reset
        roundStartedAt = block.timestamp;
        roundId += 1;
        entered = 0;
        pot = 0;

        emit Finalised(recipient, roundId);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
