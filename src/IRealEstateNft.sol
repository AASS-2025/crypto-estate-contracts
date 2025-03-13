// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title IRealEstateNFT
 * @dev Interface for the RealEstateNFT contract
 */
interface IRealEstateNFT is IERC721Metadata {
    /**
     * @dev Structure to store property metadata
     */
    struct PropertyMetadata {
        string propertyAddress;
        uint256 yearBuilt;
        bytes32 legalDocumentHash;
        uint256 longitude;
        uint256 latitude;
        uint256 squareMeters;
        bool verified;
        address verifier;
    }

    /**
     * @dev Structure to store verification requests
     */
    struct VerificationRequest {
        address verifier;
        uint256 price;
    }

    /**
     * @dev Emitted when a verification request is created
     */
    event VerificationRequestCreated(uint256 tokenId, address verifier, uint256 price);

    /**
     * @dev Returns the current token counter
     */
    function tokenCounter() external view returns (uint256);

    /**
     * @dev Returns the property metadata for a given token ID
     */
    function propertyMetadata(uint256 tokenId) external view returns (
        string memory propertyAddress,
        uint256 yearBuilt,
        bytes32 legalDocumentHash,
        uint256 longitude,
        uint256 latitude,
        uint256 squareMeters,
        bool verified,
        address verifier
    );

    /**
     * @dev Returns the verification request for a given token ID
     */
    function verificationRequests(uint256 tokenId) external view returns (
        address verifier,
        uint256 price
    );
    
    /**
     * @dev Mints a new NFT representing a real estate property
     * @param _tokenURI URI for the token metadata
     * @param _propertyAddress Physical address of the property
     * @param _yearBuilt Year the property was built
     * @param _legalDocumentHash Hash of the legal document proving ownership
     * @param _longitude Geographic longitude of the property
     * @param _latitude Geographic latitude of the property
     * @param _squareMeters Size of the property in square meters
     * @return The ID of the newly minted token
     */
    function mint(
        string memory _tokenURI,
        string memory _propertyAddress,
        uint256 _yearBuilt,
        bytes32 _legalDocumentHash,
        uint256 _longitude,
        uint256 _latitude,
        uint256 _squareMeters
    ) external returns (uint256);

    /**
     * @dev Creates a request for property verification
     * @param _tokenId ID of the token to be verified
     * @param verifier Address of the entity that will verify the property
     */
    function requestVerification(uint256 _tokenId, address verifier) external payable;

    /**
     * @dev Updates the metadata of an existing property
     * @param _tokenId ID of the token to update
     * @param _propertyAddress Updated physical address of the property
     * @param _yearBuilt Updated year the property was built
     * @param _legalDocumentHash Updated hash of the legal document proving ownership
     * @param _longitude Updated geographic longitude of the property
     * @param _latitude Updated geographic latitude of the property
     * @param _squareMeters Updated size of the property in square meters
     */
    function updateMetadata(
        uint256 _tokenId,
        string memory _propertyAddress,
        uint256 _yearBuilt,
        bytes32 _legalDocumentHash,
        uint256 _longitude,
        uint256 _latitude,
        uint256 _squareMeters
    ) external;

    /**
     * @dev Verifies a property
     * @param _tokenId ID of the token to verify
     */
    function verify(uint256 _tokenId) external;
}