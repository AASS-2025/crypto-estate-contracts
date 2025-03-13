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


    function createOffer(uint256 _tokenId, address _contractAddress, uint256 _price) public {
        require(IRealEstateNFT(_contractAddress).ownerOf(_tokenId) == msg.sender, "Not the owner of the token");
        require(IRealEstateNFT(_contractAddress).getApproved(_tokenId) == address(this), "Not approved to transfer the token");
        require(IRealEstateNFT(_contractAddress).supportsInterface(type(IRealEstateNFT).interfaceId), "NFT is not real estate NFT");

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
        address owner = IRealEstateNFT(offers[_tokenId].contractAddress).ownerOf(_tokenId);
        payable(owner).transfer(msg.value);
        IRealEstateNFT(offers[_tokenId].contractAddress).safeTransferFrom(owner, msg.sender, _tokenId);
        delete offers[_tokenId];
        emit OfferRemoved(_tokenId);
    }


}