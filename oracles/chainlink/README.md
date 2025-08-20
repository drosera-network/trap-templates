# Chainlink Oracle Trap Template

This template provides helpful view functions and monitors Chainlink oracle events including:

- Price feed updates
- Oracle node responses
- Heartbeat events
- Deviation threshold breaches
- Oracle failures and staleness

## Events Monitored

- `AnswerUpdated` - When price feeds are updated
- `NewRound` - New oracle round initiated
- `RoundRequested` - Oracle round requested
- `RoundAnswered` - Oracle round completed
- `OracleRequest` - New oracle request made
- `OracleResponse` - Oracle response received
- `ChainlinkRequested` - Chainlink request initiated
- `ChainlinkFulfilled` - Chainlink request fulfilled

## Usage

Set the `priceFeed` address to the Chainlink price feed contract you want to monitor.
Set the `oracle` address to the Chainlink oracle contract you want to monitor.

## Key Monitoring Areas

- Price feed staleness
- Large price deviations
- Oracle failures
- Heartbeat monitoring
- Request/response patterns
