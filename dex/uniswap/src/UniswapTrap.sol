// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Trap, EventFilter, EventFilterLib, EventLog} from "./Trap.sol";

struct SwapEvent {
    address sender;
    address recipient;
    int256 amount0;
    int256 amount1;
    uint160 sqrtPriceX96;
    uint128 liquidity;
    int24 tick;
}

struct MintEvent {
    address sender;
    address owner;
    int24 tickLower;
    int24 tickUpper;
    uint128 amount;
    uint256 amount0;
    uint256 amount1;
}

struct BurnEvent {
    address owner;
    int24 tickLower;
    int24 tickUpper;
    uint128 amount;
    uint256 amount0;
    uint256 amount1;
}

struct CollectEvent {
    address owner;
    address recipient;
    int24 tickLower;
    int24 tickUpper;
    uint128 amount0Requested;
    uint128 amount1Requested;
    uint128 amount0;
    uint128 amount1;
}

struct FlashEvent {
    address sender;
    address recipient;
    uint256 amount0;
    uint256 amount1;
    uint256 paid0;
    uint256 paid1;
}

// Create a struct with any data you would like to use in the shouldRespond function
struct CollectOutput {
    SwapEvent[] swapEvents;
    MintEvent[] mintEvents;
    BurnEvent[] burnEvents;
    CollectEvent[] collectEvents;
    FlashEvent[] flashEvents;
    uint256 totalVolume0;
    uint256 totalVolume1;
}

contract UniswapTrap is Trap {
    using EventFilterLib for EventFilter;

    address public immutable pool = address(0x0000000000000000000000000000000000000000); // This will be set as the Uniswap V3 pool you are monitoring

    function collect() external view override returns (bytes memory) {
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        (uint256 swapCount, uint256 mintCount, uint256 burnCount, uint256 collectCount, uint256 flashCount) =
            _countEvents(logs, filters);

        SwapEvent[] memory swapEvents = new SwapEvent[](swapCount);
        MintEvent[] memory mintEvents = new MintEvent[](mintCount);
        BurnEvent[] memory burnEvents = new BurnEvent[](burnCount);
        CollectEvent[] memory collectEvents = new CollectEvent[](collectCount);
        FlashEvent[] memory flashEvents = new FlashEvent[](flashCount);

        (uint256 totalVolume0, uint256 totalVolume1) =
            _parseEvents(logs, filters, swapEvents, mintEvents, burnEvents, collectEvents, flashEvents);

        return abi.encode(
            CollectOutput({
                swapEvents: swapEvents,
                mintEvents: mintEvents,
                burnEvents: burnEvents,
                collectEvents: collectEvents,
                flashEvents: flashEvents,
                totalVolume0: totalVolume0,
                totalVolume1: totalVolume1
            })
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));
        // loop through the data you have collected and check for anomalies
        // e.g., large swaps, unusual liquidity changes, flash loan attacks
        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](5);

        filters[0] =
            EventFilter({contractAddress: pool, signature: "Swap(address,address,int256,int256,uint160,uint128,int24)"});

        filters[1] =
            EventFilter({contractAddress: pool, signature: "Mint(address,address,int24,int24,uint128,uint256,uint256)"});

        filters[2] =
            EventFilter({contractAddress: pool, signature: "Burn(address,int24,int24,uint128,uint256,uint256)"});

        filters[3] =
            EventFilter({contractAddress: pool, signature: "Collect(address,address,int24,int24,uint128,uint128)"});

        filters[4] =
            EventFilter({contractAddress: pool, signature: "Flash(address,address,uint256,uint256,uint256,uint256)"});

        return filters;
    }

    function _getToken0() internal view returns (address) {
        return IUniswapV3Pool(pool).token0();
    }

    function _getToken1() internal view returns (address) {
        return IUniswapV3Pool(pool).token1();
    }

    function _getFee() internal view returns (uint24) {
        return IUniswapV3Pool(pool).fee();
    }

    function _getTickSpacing() internal view returns (int24) {
        return IUniswapV3Pool(pool).tickSpacing();
    }

    function _getMaxLiquidityPerTick() internal view returns (uint128) {
        return IUniswapV3Pool(pool).maxLiquidityPerTick();
    }

    function _getSlot0()
        internal
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return IUniswapV3Pool(pool).slot0();
    }

    function _getLiquidity() internal view returns (uint128) {
        return IUniswapV3Pool(pool).liquidity();
    }

    function _countEvents(EventLog[] memory logs, EventFilter[] memory filters)
        internal
        pure
        returns (uint256 swapCount, uint256 mintCount, uint256 burnCount, uint256 collectCount, uint256 flashCount)
    {
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                swapCount++;
            }
            if (filters[1].matches(log)) {
                mintCount++;
            }
            if (filters[2].matches(log)) {
                burnCount++;
            }
            if (filters[3].matches(log)) {
                collectCount++;
            }
            if (filters[4].matches(log)) {
                flashCount++;
            }
        }
    }

    function _parseEvents(
        EventLog[] memory logs,
        EventFilter[] memory filters,
        SwapEvent[] memory swapEvents,
        MintEvent[] memory mintEvents,
        BurnEvent[] memory burnEvents,
        CollectEvent[] memory collectEvents,
        FlashEvent[] memory flashEvents
    ) internal pure returns (uint256 totalVolume0, uint256 totalVolume1) {
        uint256 swapIndex = 0;
        uint256 mintIndex = 0;
        uint256 burnIndex = 0;
        uint256 collectIndex = 0;
        uint256 flashIndex = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                (swapEvents[swapIndex], totalVolume0, totalVolume1) = _parseSwapEvent(log, totalVolume0, totalVolume1);
                swapIndex++;
            }
            if (filters[1].matches(log)) {
                mintEvents[mintIndex] = _parseMintEvent(log);
                mintIndex++;
            }
            if (filters[2].matches(log)) {
                burnEvents[burnIndex] = _parseBurnEvent(log);
                burnIndex++;
            }
            if (filters[3].matches(log)) {
                collectEvents[collectIndex] = _parseCollectEvent(log);
                collectIndex++;
            }
            if (filters[4].matches(log)) {
                flashEvents[flashIndex] = _parseFlashEvent(log);
                flashIndex++;
            }
        }
    }

    function _parseSwapEvent(EventLog memory log, uint256 totalVolume0, uint256 totalVolume1)
        internal
        pure
        returns (SwapEvent memory swapEvent, uint256 newTotalVolume0, uint256 newTotalVolume1)
    {
        address sender = address(uint160(uint256(log.topics[1])));
        address recipient = address(uint160(uint256(log.topics[2])));
        (int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick) =
            abi.decode(log.data, (int256, int256, uint160, uint128, int24));

        swapEvent = SwapEvent({
            sender: sender,
            recipient: recipient,
            amount0: amount0,
            amount1: amount1,
            sqrtPriceX96: sqrtPriceX96,
            liquidity: liquidity,
            tick: tick
        });

        newTotalVolume0 = totalVolume0 + (amount0 > 0 ? uint256(amount0) : uint256(-amount0));
        newTotalVolume1 = totalVolume1 + (amount1 > 0 ? uint256(amount1) : uint256(-amount1));
    }

    function _parseMintEvent(EventLog memory log) internal pure returns (MintEvent memory mintEvent) {
        address sender = address(uint160(uint256(log.topics[1])));
        address owner = address(uint160(uint256(log.topics[2])));
        int24 tickLower = int24(uint24(uint256(log.topics[3])));
        int24 tickUpper = int24(uint24(uint256(log.topics[4])));
        (uint128 amount, uint256 amount0, uint256 amount1) = abi.decode(log.data, (uint128, uint256, uint256));

        mintEvent = MintEvent({
            sender: sender,
            owner: owner,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount: amount,
            amount0: amount0,
            amount1: amount1
        });
    }

    function _parseBurnEvent(EventLog memory log) internal pure returns (BurnEvent memory burnEvent) {
        address owner = address(uint160(uint256(log.topics[1])));
        int24 tickLower = int24(uint24(uint256(log.topics[2])));
        int24 tickUpper = int24(uint24(uint256(log.topics[3])));
        (uint128 amount, uint256 amount0, uint256 amount1) = abi.decode(log.data, (uint128, uint256, uint256));

        burnEvent = BurnEvent({
            owner: owner,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount: amount,
            amount0: amount0,
            amount1: amount1
        });
    }

    function _parseCollectEvent(EventLog memory log) internal pure returns (CollectEvent memory collectEvent) {
        address owner = address(uint160(uint256(log.topics[1])));
        int24 tickLower = int24(uint24(uint256(log.topics[2])));
        int24 tickUpper = int24(uint24(uint256(log.topics[3])));
        (address recipient, uint128 amount0Requested, uint128 amount1Requested, uint128 amount0, uint128 amount1) =
            abi.decode(log.data, (address, uint128, uint128, uint128, uint128));

        collectEvent = CollectEvent({
            owner: owner,
            recipient: recipient,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Requested: amount0Requested,
            amount1Requested: amount1Requested,
            amount0: amount0,
            amount1: amount1
        });
    }

    function _parseFlashEvent(EventLog memory log) internal pure returns (FlashEvent memory flashEvent) {
        address sender = address(uint160(uint256(log.topics[1])));
        address recipient = address(uint160(uint256(log.topics[2])));
        (uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1) =
            abi.decode(log.data, (uint256, uint256, uint256, uint256));

        flashEvent = FlashEvent({
            sender: sender,
            recipient: recipient,
            amount0: amount0,
            amount1: amount1,
            paid0: paid0,
            paid1: paid1
        });
    }
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
    function maxLiquidityPerTick() external view returns (uint128);
    function liquidity() external view returns (uint128);
}
