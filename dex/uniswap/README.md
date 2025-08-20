# Uniswap Trap

This directory contains the UniswapTrap contract for monitoring Uniswap V3 pools.

## Overview

The UniswapTrap contract extends the base Trap contract to provide comprehensive monitoring capabilities for Uniswap V3 pools. It captures and processes all major pool events including swaps, liquidity changes, and flash loans.

## Features

### Event Monitoring

- **Swap events**: When tokens are traded (most frequent)
- **Mint events**: When liquidity is added to the pool
- **Burn events**: When liquidity is removed from the pool
- **Collect events**: When fees are collected from positions
- **Flash events**: When flash loans occur

### Key Metrics Tracked

- Total trading volume for both tokens
- Liquidity additions and removals
- Fee collection patterns
- Flash loan activity

### View Functions

- `_getToken0()` / `_getToken1()`: Get pool token addresses
- `_getFee()`: Get pool fee tier (0.01%, 0.05%, 0.3%, 1%)
- `_getTickSpacing()`: Get tick spacing for the fee tier
- `_getLiquidity()`: Get current pool liquidity
- `_getSlot0()`: Get current price, tick, and other pool state
- `_getReserves()`: Get current token reserves

## Event Structures

### SwapEvent

- `sender`: Address initiating the swap
- `recipient`: Address receiving the swapped tokens
- `amount0`/`amount1`: Token amounts (positive = in, negative = out)
- `sqrtPriceX96`: Price after the swap
- `liquidity`: Current pool liquidity
- `tick`: Current tick after swap

### MintEvent

- `sender`: Address adding liquidity
- `owner`: Address that will own the position
- `tickLower`/`tickUpper`: Price range for the position
- `amount`: Liquidity amount added
- `amount0`/`amount1`: Token amounts deposited

### BurnEvent

- `owner`: Address removing liquidity
- `tickLower`/`tickUpper`: Price range of the position
- `amount`: Liquidity amount removed
- `amount0`/`amount1`: Token amounts withdrawn

## Usage

1. Deploy with the target Uniswap V3 pool address
2. Monitor all pool activity in real-time
3. Track trading volume and liquidity changes
4. Detect unusual patterns like large swaps or flash loans
5. Analyze fee collection and position management

## Anomaly Detection Ideas

- **Large swaps**: Monitor for swaps above certain thresholds
- **Liquidity manipulation**: Track unusual liquidity additions/removals
- **Flash loan attacks**: Monitor flash loan patterns and amounts
- **Price manipulation**: Track rapid price changes and tick movements
- **MEV activity**: Identify sandwich attacks and arbitrage patterns

## Note

This trap monitors the core Uniswap V3 pool contract. For additional monitoring, you might also want to track:

- Position manager events (NFT minting/burning)
- Router events (user interactions)
- Factory events (pool creation)
