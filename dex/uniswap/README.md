# Uniswap Trap Template

This template monitors Uniswap V3 DEX events including:

- Trading activities and swaps
- Liquidity provision and removal
- Position management
- Flash loans
- Fee collection

## Events Monitored

- `Swap` - When users swap tokens on the pool
- `Mint` - When liquidity is added to a position
- `Burn` - When liquidity is removed from a position
- `Collect` - When fees are collected from positions
- `Flash` - Flash loan events

## Usage

Set the `pool` address to the Uniswap V3 pool contract you want to monitor.

## Key Monitoring Areas

- Large swap volumes
- Unusual liquidity changes
- Flash loan attacks
- Position manipulation
- Fee collection patterns
