// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8;

/**
 * @title Hub v2 contract interface for Circles
 * @notice Derived from Circles v2 Hub contract
 */
interface IHub {
    enum CirclesType {
        Demurrage,
        Inflation
    }

    // Type declarations

    /**
     * @notice TrustMarker stores the expiry of a trust relation as uint96,
     * and is iterable as a linked list of trust markers.
     * @dev This is used to store the directional trust relation between two avatars,
     * and the expiry of the trust relation as uint96 in unix time.
     */
    struct TrustMarker {
        address previous;
        uint96 expiry;
    }

    struct FlowEdge {
        uint16 streamSinkId;
        uint192 amount;
    }

    struct Stream {
        uint16 sourceCoordinate;
        uint16[] flowEdgeIds; // todo: this can possible be packed more compactly manually, evaluate
        bytes data;
    }

    struct Metadata {
        bytes32 metadataType;
        bytes metadata;
        bytes erc1155UserData;
    }

    struct GroupMintMetadata {
        address group;
    }

    // External functions
    /**
     * @notice Register human allows to register an avatar for a human,
     * if they have a stopped v1 Circles contract, that has been stopped
     * before the end of the invitation period.
     * Otherwise the caller must have been invited by an already registered human avatar.
     * Humans can invite someone by trusting their address ahead of this call.
     * After the invitation period, the inviter must burn the invitation cost, and the
     * newly registered human will receive the welcome bonus.
     * @param _inviter address of the inviter, who must have trusted the caller ahead of this call.
     * If the inviter is zero, the caller can self-register if they have a stopped v1 contract
     * (stopped before the end of the invitation period).
     * @param _metadataDigest (optional) sha256 metadata digest for the avatar metadata
     * should follow ERC1155 metadata standard.
     */
    function registerHuman(address _inviter, bytes32 _metadataDigest) external;

    /**
     * @notice Register group allows to register a group avatar.
     * @param _mint mint address will be called before minting group circles
     * @param _name immutable name of the group Circles
     * @param _symbol immutable symbol of the group Circles
     * @param _metadataDigest sha256 digest for the group metadata
     */
    function registerGroup(
        address _mint,
        string calldata _name,
        string calldata _symbol,
        bytes32 _metadataDigest
    ) external;

    /**
     * @notice Register custom group allows to register a group with a custom treasury contract.
     * @param _mint mint address will be called before minting group circles
     * @param _treasury treasury address for receiving collateral
     * @param _name immutable name of the group Circles
     * @param _symbol immutable symbol of the group Circles
     * @param _metadataDigest metadata digest for the group metadata
     */
    function registerCustomGroup(
        address _mint,
        address _treasury,
        string calldata _name,
        string calldata _symbol,
        bytes32 _metadataDigest
    ) external;

    /**
     * @notice Register organization allows to register an organization avatar.
     * @param _name name of the organization
     * @param _metadataDigest Metadata digest for the organization metadata
     */
    function registerOrganization(
        string calldata _name,
        bytes32 _metadataDigest
    ) external;

    /**
     * @notice Trust allows to trust another address for a certain period of time.
     * Expiry times in the past are set to the current block timestamp.
     * @param _trustReceiver address that is trusted by the caller. The trust receiver
     * does not (yet) need to be registered as an avatar.
     * @param _expiry expiry time in seconds since unix epoch until when trust is valid
     * @dev Trust is directional and can be set by the caller to any address.
     * The trusted address does not (yet) have to be registered in the Hub contract.
     */
    function trust(address _trustReceiver, uint96 _expiry) external;

    /**
     * @notice Personal mint allows to mint personal Circles for a registered human avatar.
     */
    function personalMint() external;

    /**
     * @notice Calculate the demurraged issuance for a human's avatar.
     * @param _human Address of the human's avatar to calculate the issuance for.
     * @return issuance The issuance in attoCircles.
     * @return startPeriod The start of the claimable period.
     * @return endPeriod The end of the claimable period.
     */
    function calculateIssuance(
        address _human
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Calculate issuance allows to calculate the issuance for a human avatar with a check
     * to update the v1 mint status if updated.
     * @param _human address of the human avatar to calculate the issuance for
     * @return issuance amount of Circles that can be minted
     * @return startPeriod start of the claimable period
     * @return endPeriod end of the claimable period
     */
    function calculateIssuanceWithCheck(
        address _human
    ) external returns (uint256, uint256, uint256);

    /**
     * @notice Group mint allows to mint group Circles by providing the required collateral.
     * @param _group address of the group avatar to mint Circles of
     * @param _collateralAvatars array of (personal or group) avatar addresses to be used as collateral
     * @param _amounts array of amounts of collateral to be used for minting
     * @param _data (optional) additional data to be passed to the mint policy, treasury and minter (caller)
     */
    function groupMint(
        address _group,
        address[] calldata _collateralAvatars,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    /**
     * @notice Stop allows to stop future mints of personal Circles for this avatar.
     * Must be called by the avatar itself. This action is irreversible.
     */
    function stop() external;

    /**
     * Stopped checks whether the avatar has stopped future mints of personal Circles.
     * @param _human address of avatar of the human to check whether it is stopped
     */
    function stopped(address _human) external view returns (bool);

    /**
     * @notice Migrate allows to migrate v1 Circles to v2 Circles. During bootstrap period,
     * no invitation cost needs to be paid for new humans to be registered. After the bootstrap
     * period the same invitation cost applies as for normal invitations, and this requires the
     * owner to be a human and to have enough personal Circles to pay the invitation cost.
     * Organizations and groups have to ensure all humans have been registered after the bootstrap period.
     * Can only be called by the migration contract.
     * @param _owner address of the owner of the v1 Circles and beneficiary of the v2 Circles
     * @param _avatars array of avatar addresses to migrate
     * @param _amounts array of amounts in inflationary v1 units to migrate
     */
    function migrate(
        address _owner,
        address[] calldata _avatars,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Burn allows to burn Circles owned by the caller.
     * @param _id Circles identifier of the Circles to burn
     * @param _amount amount of Circles to burn
     * @param _data (optional) additional data to be passed to the burn policy if they are group Circles
     */
    function burn(uint256 _id, uint256 _amount, bytes calldata _data) external;

    function wrap(
        address _avatar,
        uint256 _amount,
        CirclesType _type
    ) external returns (address);

    function operateFlowMatrix(
        address[] calldata _flowVertices,
        FlowEdge[] calldata _flow,
        Stream[] calldata _streams,
        bytes calldata _packedCoordinates
    ) external;

    /**
     * @notice Set the advanced usage flag for the caller's avatar.
     * @param _flag advanced usage flags combination to set
     */
    function setAdvancedUsageFlag(bytes32 _flag) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    // Public functions

    /**
     * Checks if an avatar is registered as a human.
     * @param _human address of the human to check
     */
    function isHuman(address _human) external view returns (bool);

    /**
     * Checks if an avatar is registered as a group.
     * @param _group address of the group to check
     */
    function isGroup(address _group) external view returns (bool);

    /**
     * @notice Checks if an avatar is registered as an organization.
     * @param _organization address of the organization to check
     */
    function isOrganization(address _organization) external view returns (bool);

    /**
     * @notice Returns true if the truster trusts the trustee.
     * @param _truster Address of the trusting account
     * @param _trustee Address of the trusted account
     */
    function isTrusted(
        address _truster,
        address _trustee
    ) external view returns (bool);

    /**
     * @notice Returns true if the flow to the receiver is permitted. By default avatars don't have
     * consented flow enabled, so then this function is equivalent to isTrusted(). This function is called
     * to check whether the flow edge is permitted (either along a path's flow edge, or upon groupMint).
     * If the sender avatar has enabled consented flow for the Circles balances they own,
     * then the receiver must trust the Circles being sent, and the sender must trust the receiver,
     * and to preserve the protection recursively the receiver themselves must have consented flow enabled.
     * @param _from Address of the sender
     * @param _to Address of the receiver
     * @param _circlesAvatar Address of the Circles avatar of the Circles being sent
     * @return permitted true if the flow is permitted, false otherwise
     */
    function isPermittedFlow(
        address _from,
        address _to,
        address _circlesAvatar
    ) external view returns (bool);
}
