// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./Interface/IIdentityRegistry.sol";
import "./Interface/IDIDValidator.sol";

/**
 * @title AgentRegistry
 * @dev Registry for AI agents with native token registration fee and meta-transaction support
 * @notice This contract manages agent registrations with DIDs and service endpoints
 *
 * Features:
 * - Native token registration fee (0.01 ETH)
 * - EIP-712 signature based registration for gas-less onboarding
 * - Service endpoint management
 * - Agent lookup by address and ID
 *
 * Version: 1.0.0
 * Author: Vkpatva
 */
contract AgentRegistry is IAgentRegistry, EIP712 {
    // ============ Constants ============
    string public constant VERSION = "1.0.0";
    string private constant SIGNING_DOMAIN = "AgentRegistry";
    string private constant SIGNATURE_VERSION = "1";
    // uint256 private constant REGISTRATION_FEE = 0.01 ether;
    uint256 private REGISTRATION_FEE;
    // ============ EIP-712 Typehash ============
    bytes32 private constant AGENT_TYPEHASH =
        keccak256(
            "AgentRegistration(address agent,string did,string description,string serviceEndpoint,uint256 nonce,uint256 expiry)"
        );

    // ============ State Variables ============
    uint256 private _nextAgentId = 1;
    IDIDValidator public immutable didValidator;
    mapping(address => AgentInfo) private _agentsByAddress;
    mapping(uint256 => address) private _addressById;
    mapping(string => uint256) private _didToAgentId; // For DID uniqueness
    mapping(string => address) private _endpointToAgent; // For service endpoint lookup
    mapping(address => uint256) public nonces;

    constructor(
        address validator,
        uint decimals // = 1
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        if (validator == address(0)) revert InvalidDIDValidatorAddress();
        didValidator = IDIDValidator(validator);
        //  10 ^ 4 = 10000
        REGISTRATION_FEE = (1 * 10) ^ decimals;
    }

    /**
     * @notice Register a new agent with DID and service endpoint
     * @param did Decentralized Identifier
     * @param description Free-form description about the agent
     * @param serviceEndpoint Service endpoint URL for the agent
     */
    function registerAgent(
        string calldata did,
        string calldata description,
        string calldata serviceEndpoint
    ) external payable override {
        if (msg.value < REGISTRATION_FEE) revert InsufficientRegistrationFee();
        if (bytes(did).length == 0) revert DIDCannotBeEmpty();

        // Check uniqueness and validate DID
        _checkUniqueness(did, msg.sender, serviceEndpoint);
        if (!didValidator.validateDID(did, msg.sender)) {
            revert DIDAddressMismatch();
        }

        _registerAgent(msg.sender, did, description, serviceEndpoint);
    }

    /**
     * @notice Register agent through a gas payer using EIP-712 signature
     * @param request The forward request containing agent details
     * @param signature EIP-712 signature signed by the agent
     */
    function registerAgentWithSig(
        ForwardRequest calldata request,
        bytes calldata signature
    ) external payable override {
        if (msg.value < REGISTRATION_FEE) revert InsufficientRegistrationFee();
        if (block.timestamp > request.expiry) revert RequestExpired();
        if (nonces[request.agent] != request.nonce) revert InvalidNonce();

        // Check uniqueness and validate DID
        _checkUniqueness(request.did, request.agent, request.serviceEndpoint);
        if (!didValidator.validateDID(request.did, request.agent)) {
            revert DIDAddressMismatch();
        }

        // Build struct hash
        bytes32 structHash = keccak256(
            abi.encode(
                AGENT_TYPEHASH,
                request.agent,
                keccak256(bytes(request.did)),
                keccak256(bytes(request.description)),
                keccak256(bytes(request.serviceEndpoint)),
                request.nonce,
                request.expiry
            )
        );

        // Final digest per EIP-712
        bytes32 digest = _hashTypedDataV4(structHash);

        // Recover and verify signer
        address recovered = ECDSA.recover(digest, signature);
        if (recovered != request.agent) revert InvalidSignature();

        nonces[request.agent]++;
        _registerAgent(
            request.agent,
            request.did,
            request.description,
            request.serviceEndpoint
        );
    }

    function updateServiceEndpoint(
        string calldata newEndpoint
    ) external override {
        if (_agentsByAddress[msg.sender].id == 0) revert AgentNotFound();

        // Check if new endpoint is already taken by another agent
        address existingAgent = _endpointToAgent[newEndpoint];
        if (existingAgent != address(0) && existingAgent != msg.sender) {
            revert ServiceEndpointAlreadyRegisteredByAnotherAgent();
        }

        // Remove old endpoint mapping
        string memory oldEndpoint = _agentsByAddress[msg.sender]
            .serviceEndpoint;
        delete _endpointToAgent[oldEndpoint];

        // Update agent info and add new endpoint mapping
        _agentsByAddress[msg.sender].serviceEndpoint = newEndpoint;
        _endpointToAgent[newEndpoint] = msg.sender;

        emit ServiceEndpointUpdated(
            _agentsByAddress[msg.sender].id,
            newEndpoint
        );
    }

    function getAgentByAddress(
        address agent
    ) external view override returns (AgentInfo memory) {
        if (_agentsByAddress[agent].id == 0) revert AgentNotFound();
        return _agentsByAddress[agent];
    }

    function getAgentById(
        uint256 agentId
    ) external view override returns (AgentInfo memory) {
        address agent = _addressById[agentId];
        if (agent == address(0)) revert AgentNotFound();
        return _agentsByAddress[agent];
    }

    function getAgentDID(
        address agent
    ) external view override returns (string memory) {
        if (_agentsByAddress[agent].id == 0) revert AgentNotFound();
        return _agentsByAddress[agent].did;
    }

    function getAgentServiceEndpoint(
        address agent
    ) external view override returns (string memory) {
        if (_agentsByAddress[agent].id == 0) revert AgentNotFound();
        return _agentsByAddress[agent].serviceEndpoint;
    }

    function getAgentByServiceEndpoint(
        string calldata serviceEndpoint
    ) external view returns (AgentInfo memory) {
        address agent = _endpointToAgent[serviceEndpoint];
        if (agent == address(0)) revert AgentNotFoundForEndpoint();
        return _agentsByAddress[agent];
    }

    function _registerAgent(
        address agent,
        string calldata did,
        string calldata description,
        string calldata serviceEndpoint
    ) private {
        uint256 agentId = _nextAgentId++;

        _agentsByAddress[agent] = AgentInfo({
            did: did,
            id: agentId,
            description: description,
            serviceEndpoint: serviceEndpoint
        });

        _addressById[agentId] = agent;
        _didToAgentId[did] = agentId;
        _endpointToAgent[serviceEndpoint] = agent;

        emit AgentRegistered(agent, did, agentId);
    }

    /**
     * @notice Validate uniqueness of DID, address, and service endpoint
     */
    function _checkUniqueness(
        string calldata did,
        address agent,
        string calldata serviceEndpoint
    ) internal view {
        if (_agentsByAddress[agent].id != 0) {
            revert AddressAlreadyRegistered();
        }
        if (_didToAgentId[did] != 0) {
            revert DIDAlreadyRegistered();
        }
        if (_endpointToAgent[serviceEndpoint] != address(0)) {
            revert ServiceEndpointAlreadyRegistered();
        }
    }
}
