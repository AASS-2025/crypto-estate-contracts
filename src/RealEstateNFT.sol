// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./IRealEstateNft.sol";

contract RealEstateNFT is ERC721URIStorage {

    uint256 public tokenCounter;
    struct PropertyMetadata {
        string propertyAddress;
        uint256 yearBuilt;
        bytes32 legalDocumentHash;
        uint256 longitude;
        uint256 latitude;
        uint256 squereMeters;
        bool verified;
        address verifier;
    }

    struct VerificationRequest {
        address verifier;
        uint256 price;
    }

    mapping(uint256 => PropertyMetadata) public propertyMetadata;
    mapping(uint256 => VerificationRequest) public verificationRequests;
    event VerificationRequestCreated(uint256 tokenId, address verifier, uint256 price);

    constructor() ERC721("RealEstateNFT", "RENFT") {
        tokenCounter = 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage) returns (bool) {
        return interfaceId == type(IRealEstateNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(
        string memory _tokenURI,
        string memory _propertyAddress,
        uint256 _yearBuilt,
        bytes32 _legalDocumentHash,
        uint256 _longitude,
        uint256 _latitude,
        uint256 _squereMeters
    ) public returns (uint256) {
        tokenCounter++;
        _safeMint(msg.sender, tokenCounter);
        _setTokenURI(tokenCounter, _tokenURI);
        propertyMetadata[tokenCounter] = PropertyMetadata(
            _propertyAddress,
            _yearBuilt,
            _legalDocumentHash,
            _longitude,
            _latitude,
            _squereMeters,
            false,
            address(0)
        );
        return tokenCounter;
    }

    function requestVerification(uint256 _tokenId, address verifier) payable public {
        _requireOwned(_tokenId);
        if(verificationRequests[_tokenId].verifier != address(0)) {
            payable(msg.sender).transfer(verificationRequests[_tokenId].price);
        }
        verificationRequests[_tokenId] = VerificationRequest(verifier, msg.value);
        emit VerificationRequestCreated(_tokenId, verifier, msg.value);
    }

    function updateMetadata(
        uint256 _tokenId,
        string memory _propertyAddress,
        uint256 _yearBuilt,
        bytes32 _legalDocumentHash,
        uint256 _longitude,
        uint256 _latitude,
        uint256 _squereMeters
    ) public {
        _requireOwned(_tokenId);
        propertyMetadata[_tokenId] = PropertyMetadata(
            _propertyAddress,
            _yearBuilt,
            _legalDocumentHash,
            _longitude,
            _latitude,
            _squereMeters,
            false,
            address(0)
        );
        emit MetadataUpdate(_tokenId);
    }

    function verify(uint256 _tokenId) public {
        require(verificationRequests[_tokenId].verifier == msg.sender, "You are not the verifier");
        propertyMetadata[_tokenId].verified = true;
        propertyMetadata[_tokenId].verifier = msg.sender;
        payable(msg.sender).transfer(verificationRequests[_tokenId].price);
        verificationRequests[_tokenId].price = 0;
        verificationRequests[_tokenId].verifier = address(0);
        emit MetadataUpdate(_tokenId);
    }
}






