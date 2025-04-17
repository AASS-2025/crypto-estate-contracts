// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RealEstateNFT.sol";
import "../src/RealEstateMarket.sol";
import "../src/IRealEstateNft.sol";

contract RealEstateTest is Test {
    RealEstateNFT public nft;
    RealEstateMarket public market;
    
    address public owner;
    address public buyer;
    address public verifier;
    
    string constant TOKEN_URI = "ipfs://QmXZQeZjpM8sG6Pt3jFhxxgTuLg1nFn2LiLJjYu6hgNs5T";
    string constant PROPERTY_ADDRESS = "123 Main St, Anytown, USA";
    uint256 constant YEAR_BUILT = 2020;
    bytes32 constant LEGAL_DOCUMENT_HASH = keccak256(abi.encodePacked("Legal deed for 123 Main St"));
    uint256 constant LONGITUDE = 42196151; // Represents 42.196151
    uint256 constant LATITUDE = 24025198; // Represents 24.025198
    uint256 constant SQUARE_METERS = 150;
    uint256 constant PRICE = 5 ether;
    
    function setUp() public {
        // Use makeAddr to create proper EOA addresses
        owner = makeAddr("owner");
        buyer = makeAddr("buyer");
        verifier = makeAddr("verifier");
        
        vm.startPrank(owner);
        nft = new RealEstateNFT();
        market = new RealEstateMarket();
        vm.stopPrank();
    }
    
    function testMintNFT() public {
        vm.startPrank(owner);
        
        uint256 tokenId = nft.mint(
            TOKEN_URI,
            PROPERTY_ADDRESS,
            YEAR_BUILT,
            LEGAL_DOCUMENT_HASH,
            LONGITUDE,
            LATITUDE,
            SQUARE_METERS
        );
        
        assertEq(tokenId, 1, "TokenId should be 1");
        assertEq(nft.ownerOf(tokenId), owner, "Owner should be the minter");
        assertEq(nft.tokenURI(tokenId), TOKEN_URI, "TokenURI should match");
        
        // Verify property metadata
        (
            string memory propertyAddress,
            uint256 yearBuilt,
            bytes32 legalDocumentHash,
            uint256 longitude,
            uint256 latitude,
            uint256 squareMeters,
            bool verified,
            address storedVerifier
        ) = nft.propertyMetadata(tokenId);
        
        assertEq(propertyAddress, PROPERTY_ADDRESS);
        assertEq(yearBuilt, YEAR_BUILT);
        assertEq(legalDocumentHash, LEGAL_DOCUMENT_HASH);
        assertEq(longitude, LONGITUDE);
        assertEq(latitude, LATITUDE);
        assertEq(squareMeters, SQUARE_METERS);
        assertEq(verified, false);
        assertEq(storedVerifier, address(0));
        
        vm.stopPrank();
    }
    
    function testApproveAndCreateOffer() public {
        // First mint the NFT
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(
            TOKEN_URI,
            PROPERTY_ADDRESS,
            YEAR_BUILT,
            LEGAL_DOCUMENT_HASH,
            LONGITUDE,
            LATITUDE,
            SQUARE_METERS
        );
        
        // Approve the market contract to transfer the NFT
        nft.approve(address(market), tokenId);
        
        // Check approval was set correctly
        assertEq(nft.getApproved(tokenId), address(market), "Market should be approved");
        
        // Create an offer on the marketplace
        market.createOffer(tokenId, address(nft), PRICE);
        
        // Verify offer was created correctly
        (
            address contractAddress,
            uint256 listedTokenId,
            uint256 listedPrice,
            bool active
        ) = market.offers(tokenId);
        
        assertEq(contractAddress, address(nft), "Contract address should match");
        assertEq(listedTokenId, tokenId, "TokenId should match");
        assertEq(listedPrice, PRICE, "Price should match");
        assertTrue(active, "Offer should be active");
        
        vm.stopPrank();
    }
    
    function testBuyOffer() public {
        // Mint and list first
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(
            TOKEN_URI,
            PROPERTY_ADDRESS,
            YEAR_BUILT,
            LEGAL_DOCUMENT_HASH,
            LONGITUDE,
            LATITUDE,
            SQUARE_METERS
        );
        nft.approve(address(market), tokenId);
        market.createOffer(tokenId, address(nft), PRICE);
        vm.stopPrank();
        
        // Record owner's initial balance
        uint256 ownerInitialBalance = owner.balance;
        
        // Buyer purchases the NFT
        vm.startPrank(buyer);
        vm.deal(buyer, PRICE); // Give buyer enough ETH
        market.buyOffer{value: PRICE}(tokenId);
        
        // Verify ownership changed
        assertEq(nft.ownerOf(tokenId), buyer, "Buyer should now own the NFT");
        
        // Verify offer was marked as inactive (not completely deleted)
        (,, uint256 price, bool active) = market.offers(tokenId);
        assertFalse(active, "Offer should no longer be active");
        
        vm.stopPrank();
        
        // Verify owner received payment
        assertEq(owner.balance, ownerInitialBalance + PRICE, "Owner should have received payment");
    }
    
    function testRemoveOffer() public {
        // Mint and list first
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(
            TOKEN_URI,
            PROPERTY_ADDRESS,
            YEAR_BUILT,
            LEGAL_DOCUMENT_HASH,
            LONGITUDE,
            LATITUDE,
            SQUARE_METERS
        );
        nft.approve(address(market), tokenId);
        market.createOffer(tokenId, address(nft), PRICE);
        
        // Now remove the offer
        market.removeOffer(tokenId);
        
        // Verify offer was removed
        (,, uint256 price, bool active) = market.offers(tokenId);
        assertEq(price, 0, "Price should be reset");
        assertFalse(active, "Offer should no longer be active");
        
        vm.stopPrank();
    }
    
    function testVerificationFlow() public {
        // Mint first
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(
            TOKEN_URI,
            PROPERTY_ADDRESS,
            YEAR_BUILT,
            LEGAL_DOCUMENT_HASH,
            LONGITUDE,
            LATITUDE,
            SQUARE_METERS
        );
        
        // Request verification with 1 ETH payment
        uint256 verificationFee = 1 ether;
        vm.deal(owner, verificationFee);
        nft.requestVerification{value: verificationFee}(tokenId, verifier);
        
        // Check verification request is stored
        (address storedVerifier, uint256 storedPrice) = nft.verificationRequests(tokenId);
        assertEq(storedVerifier, verifier, "Verifier should match");
        assertEq(storedPrice, verificationFee, "Price should match");
        
        vm.stopPrank();
        
        // Verifier confirms verification
        vm.startPrank(verifier);
        uint256 verifierBalanceBefore = verifier.balance;
        nft.verify(tokenId);
        
        // Check verifier got paid
        assertEq(verifier.balance - verifierBalanceBefore, verificationFee, "Verifier should be paid");
        
        // Check property is now verified
        (,,,,,, bool verified, address propertyVerifier) = nft.propertyMetadata(tokenId);
        assertTrue(verified, "Property should be marked as verified");
        assertEq(propertyVerifier, verifier, "Verifier should be recorded");
        
        // Check verification request is reset
        (address resetVerifier, uint256 resetPrice) = nft.verificationRequests(tokenId);
        assertEq(resetVerifier, address(0), "Verifier should be reset");
        assertEq(resetPrice, 0, "Price should be reset");
        
        vm.stopPrank();
    }
    
    function testFullFlow() public {
        // 1. Mint an NFT
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(
            TOKEN_URI,
            PROPERTY_ADDRESS,
            YEAR_BUILT,
            LEGAL_DOCUMENT_HASH,
            LONGITUDE,
            LATITUDE,
            SQUARE_METERS
        );
        
        // 2. Get it verified
        uint256 verificationFee = 1 ether;
        vm.deal(owner, verificationFee);
        nft.requestVerification{value: verificationFee}(tokenId, verifier);
        vm.stopPrank();
        
        vm.startPrank(verifier);
        nft.verify(tokenId);
        vm.stopPrank();
        
        // Record owner's initial balance
        uint256 ownerInitialBalance = owner.balance;
        
        // 3. List the NFT for sale
        vm.startPrank(owner);
        // Make sure to approve the marketplace for this specific token
        nft.approve(address(market), tokenId);
        market.createOffer(tokenId, address(nft), PRICE);
        vm.stopPrank();
        
        // 4. Buyer purchases the NFT
        vm.startPrank(buyer);
        vm.deal(buyer, PRICE);
        market.buyOffer{value: PRICE}(tokenId);
        vm.stopPrank();
        
        // 5. Verify final state
        assertEq(nft.ownerOf(tokenId), buyer, "Buyer should own the NFT");
        assertEq(owner.balance, ownerInitialBalance + PRICE, "Owner should have been paid");
        
        // Check that the offer was marked as inactive (not completely deleted)
        (,, , bool active) = market.offers(tokenId);
        assertFalse(active, "Offer should no longer be active");
        
        (,,,,,, bool verified,) = nft.propertyMetadata(tokenId);
        assertTrue(verified, "Property should still be verified");
    }
}