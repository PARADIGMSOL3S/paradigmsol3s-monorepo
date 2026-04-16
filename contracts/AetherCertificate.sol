// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract AetherCertificate is ERC721, AccessControl, Pausable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 300;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    enum Phase {
        Closed,
        Founding,
        Club,
        Public
    }

    struct SaleStatus {
        Phase phase;
        bool paused;
        uint256 maxSupply;
        uint256 minted;
        uint256 remaining;
        bytes32 foundingRoot;
        bytes32 clubRoot;
        address treasury;
        address royaltyReceiver;
    }

    event Minted(address indexed recipient, uint256 indexed tokenId, Phase indexed phase);
    event PhaseChanged(Phase indexed previousPhase, Phase indexed newPhase);
    event MerkleRootSet(Phase indexed phase, bytes32 indexed newRoot);
    event TreasurySet(address indexed previousTreasury, address indexed newTreasury);
    event RoyaltyReceiverSet(address indexed previousReceiver, address indexed newReceiver);
    event DeliveryProcessed(bytes32 indexed deliveryHash, address indexed recipient, uint8 phaseId);

    error SupplyCapExceeded();
    error AlreadyMinted();
    error InvalidPhase();
    error InvalidProof();
    error DeliveryAlreadyProcessed();
    error ZeroAddress();
    error Unauthorized();

    Phase public phase;
    bytes32 public foundingRoot;
    bytes32 public clubRoot;

    address public treasury;
    address public royaltyReceiver;

    uint256 private _minted;
    string private _baseTokenURI;

    mapping(address => bool) public hasMinted;
    mapping(bytes32 => bool) public processedDeliveries;

    constructor(address admin, address operator, address treasury_, address royaltyReceiver_, string memory baseUri)
        ERC721("Aether Certificate", "AETHCERT")
    {
        if (admin == address(0) || operator == address(0) || treasury_ == address(0) || royaltyReceiver_ == address(0)) {
            revert ZeroAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);

        treasury = treasury_;
        royaltyReceiver = royaltyReceiver_;
        _baseTokenURI = baseUri;
        phase = Phase.Closed;
    }

    function setPhase(Phase newPhase) external onlyRole(OPERATOR_ROLE) {
        Phase previous = phase;
        phase = newPhase;
        emit PhaseChanged(previous, newPhase);
    }

    function setMerkleRoot(Phase rootPhase, bytes32 root) external onlyRole(OPERATOR_ROLE) {
        if (rootPhase == Phase.Founding) {
            foundingRoot = root;
        } else if (rootPhase == Phase.Club) {
            clubRoot = root;
        } else {
            revert InvalidPhase();
        }

        emit MerkleRootSet(rootPhase, root);
    }

    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) revert ZeroAddress();
        address previous = treasury;
        treasury = newTreasury;
        emit TreasurySet(previous, newTreasury);
    }

    function setRoyaltyReceiver(address newRoyaltyReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newRoyaltyReceiver == address(0)) revert ZeroAddress();
        address previous = royaltyReceiver;
        royaltyReceiver = newRoyaltyReceiver;
        emit RoyaltyReceiverSet(previous, newRoyaltyReceiver);
    }

    function setBaseURI(string calldata baseUri) external onlyRole(OPERATOR_ROLE) {
        _baseTokenURI = baseUri;
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function mintFounding(bytes32[] calldata proof) external nonReentrant whenNotPaused {
        if (phase != Phase.Founding) revert InvalidPhase();
        _validateProof(foundingRoot, msg.sender, proof);
        _mintCertificate(msg.sender, Phase.Founding);
    }

    function mintClub(bytes32[] calldata proof) external nonReentrant whenNotPaused {
        if (phase != Phase.Club) revert InvalidPhase();
        _validateProof(clubRoot, msg.sender, proof);
        _mintCertificate(msg.sender, Phase.Club);
    }

    function mintPublic() external nonReentrant whenNotPaused {
        if (phase != Phase.Public) revert InvalidPhase();
        _mintCertificate(msg.sender, Phase.Public);
    }

    function processWormholeDelivery(bytes32 deliveryHash, address recipient, uint8 phaseId, bytes32[] calldata proof)
        external
        onlyRole(OPERATOR_ROLE)
        nonReentrant
        whenNotPaused
    {
        if (processedDeliveries[deliveryHash]) revert DeliveryAlreadyProcessed();

        processedDeliveries[deliveryHash] = true;
        emit DeliveryProcessed(deliveryHash, recipient, phaseId);

        Phase mintPhase = Phase(phaseId);
        if (mintPhase == Phase.Founding) {
            _validateProof(foundingRoot, recipient, proof);
        } else if (mintPhase == Phase.Club) {
            _validateProof(clubRoot, recipient, proof);
        } else if (mintPhase != Phase.Public) {
            revert InvalidPhase();
        }

        _mintCertificate(recipient, mintPhase);
    }

    function burn(uint256 tokenId) external {
        address holder = ownerOf(tokenId);
        if (msg.sender != holder) revert Unauthorized();
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string.concat(_baseURI(), tokenId.toString(), ".json");
    }

    function saleStatus() external view returns (SaleStatus memory) {
        uint256 mintedCount = _totalMinted();
        return SaleStatus({
            phase: phase,
            paused: paused(),
            maxSupply: MAX_SUPPLY,
            minted: mintedCount,
            remaining: MAX_SUPPLY - mintedCount,
            foundingRoot: foundingRoot,
            clubRoot: clubRoot,
            treasury: treasury,
            royaltyReceiver: royaltyReceiver
        });
    }

    function _validateProof(bytes32 root, address account, bytes32[] calldata proof) internal pure {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encodePacked(account))));
        if (!MerkleProof.verifyCalldata(proof, root, leaf)) revert InvalidProof();
    }

    function _mintCertificate(address recipient, Phase mintPhase) internal {
        if (hasMinted[recipient]) revert AlreadyMinted();
        if (_totalMinted() >= MAX_SUPPLY) revert SupplyCapExceeded();

        uint256 tokenId = _minted + 1;
        _minted = tokenId;
        hasMinted[recipient] = true;
        _safeMint(recipient, tokenId);

        emit Minted(recipient, tokenId, mintPhase);
    }

    function _totalMinted() internal view returns (uint256) {
        return _minted;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
