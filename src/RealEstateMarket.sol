// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IRealEstateNft.sol";

contract RealEstateMarket {

    struct Offer {
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        bool active;   
    }
    
    mapping(uint256 => Offer) public offers;

    event OfferCreated(uint256 tokenId, address contractAddress, uint256 price);
    event OfferRemoved(uint256 tokenId);
    event OfferSold(uint256 tokenId, address buyer, uint256 price);

    function createOffer(uint256 _tokenId, address _contractAddress, uint256 _price) public {
        address owner = IRealEstateNFT(_contractAddress).ownerOf(_tokenId);
        require(owner == msg.sender, "Not the owner of the token");
        // require(IRealEstateNFT(_contractAddress).getApproved(_tokenId) == address(this), "Not approved to transfer the token");
        require(
            IRealEstateNFT(_contractAddress).getApproved(_tokenId) == address(this) ||
            IRealEstateNFT(_contractAddress).isApprovedForAll(owner, address(this)),
            "Marketplace not approved to transfer the token"
        );
        // require(IRealEstateNFT(_contractAddress).supportsInterface(type(IRealEstateNFT).interfaceId), "NFT is not real estate NFT");

        offers[_tokenId] = Offer(_contractAddress, _tokenId, _price, true);
        emit OfferCreated(_tokenId, _contractAddress, _price);
    }

    function removeOffer(uint256 _tokenId) public {
        require(offers[_tokenId].active, "Offer is not active");
        require(IRealEstateNFT(offers[_tokenId].contractAddress).ownerOf(_tokenId) == msg.sender, "Not the owner of the token");
        delete offers[_tokenId];
        emit OfferRemoved(_tokenId);
    }

    function buyOffer(uint256 _tokenId) public payable {
        require(offers[_tokenId].active, "Offer is not active");
        require(msg.value == offers[_tokenId].price, "Incorrect price");
        
        address seller = IRealEstateNFT(offers[_tokenId].contractAddress).ownerOf(_tokenId);
        
        // Update the offer status before making external calls (reentrancy protection)
        offers[_tokenId].active = false;
        
        // Transfer the NFT first
        IRealEstateNFT(offers[_tokenId].contractAddress).safeTransferFrom(seller, msg.sender, _tokenId);
        
        // Then transfer the ETH
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "ETH transfer failed");
        
        emit OfferSold(_tokenId, msg.sender, msg.value);
        emit OfferRemoved(_tokenId);
    }
}