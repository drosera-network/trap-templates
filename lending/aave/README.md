# Aave Trap Template

This template includes helpful view functions and basic Aave lending protocol events including:

- Lending and borrowing activities
- Liquidations
- Interest rate changes
- Reserve updates
- Flash loans
- User interactions

## Events Monitored

- `Supply` - When users supply assets to the protocol
- `Borrow` - When users borrow assets from the protocol
- `Repay` - When users repay borrowed assets
- `LiquidationCall` - When positions are liquidated
- `FlashLoan` - Flash loan events
- `ReserveDataUpdated` - Interest rate and reserve parameter updates
- `ReserveUsedAsCollateralEnabled/Disabled` - Collateral changes
- `Swap` - Interest rate swap events

## Usage

Set the `poolDataProvider` address to the Aave Pool Data Provider contract you want to monitor.
