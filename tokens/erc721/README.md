# ERC721 Trap

This directory contains the ERC721Trap contract for monitoring ERC721 (NFT) tokens.

## Overview

The ERC721Trap contract extends the base Trap contract to provide monitoring capabilities for ERC721 tokens. It captures and processes the following events:

- **Transfer events**: When NFTs are transferred between addresses
- **Approval events**: When specific token approvals are granted
- **ApprovalForAll events**: When operators are approved to manage all tokens

## Features

### Event Monitoring

- Monitors Transfer(address,address,uint256) events
- Monitors Approval(address,address,uint256) events
- Monitors ApprovalForAll(address,address,bool) events

### View Functions

- `_getBalance(address account)`: Get the number of NFTs owned by an account
- `_getOwnerOf(uint256 tokenId)`: Get the owner of a specific token ID
- `_getApproved(uint256 tokenId)`: Get the approved address for a specific token
- `_isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all tokens
- `_getName()`: Get the token collection name
- `_getSymbol()`: Get the token collection symbol
- `_getTokenURI(uint256 tokenId)`: Get the metadata URI for a specific token

### Data Collection

The `collect()` function returns a `CollectOutput` struct containing:

- Array of transfer events
- Array of approval events
- Array of approval for all events
- Total supply (note: ERC721 doesn't have a standard totalSupply function)

## Usage

1. Deploy the contract with the target ERC721 token address
2. The contract will automatically monitor events from the specified token
3. Use the `collect()` function to gather event data
4. Implement custom logic in `shouldRespond()` to detect anomalies

## Note

Unlike ERC20 tokens, ERC721 tokens don't have a standard `totalSupply()` function. The `_getTotalSupply()` function returns 0 by default and would need to be customized based on the specific token implementation if total supply tracking is required.
