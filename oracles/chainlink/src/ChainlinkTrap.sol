// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";

struct AnswerUpdatedEvent {
    int256 current;
    uint256 roundId;
    uint256 updatedAt;
}

struct NewRoundEvent {
    uint256 roundId;
    address startedBy;
    uint256 startedAt;
}

struct RoundRequestedEvent {
    address requester;
    uint256 roundId;
    uint256 timestamp;
}

struct RoundAnsweredEvent {
    uint256 roundId;
    address answerer;
    uint256 timestamp;
}

struct OracleRequestEvent {
    bytes32 specId;
    address requester;
    bytes32 requestId;
    uint256 payment;
    address callbackAddr;
    bytes4 callbackFunctionId;
    uint256 cancelExpiration;
    uint256 dataVersion;
    bytes data;
}

struct OracleResponseEvent {
    bytes32 requestId;
    address requester;
    bytes32 specId;
    address oracle;
    bytes32 callbackFunctionId;
    uint256 expiration;
    bytes data;
}

struct ChainlinkRequestedEvent {
    bytes32 specId;
    address requester;
    bytes32 requestId;
    uint256 payment;
    address callbackAddr;
    bytes4 callbackFunctionId;
    uint256 cancelExpiration;
    uint256 dataVersion;
    bytes data;
}

struct ChainlinkFulfilledEvent {
    bytes32 requestId;
    uint256 payment;
    address callbackAddr;
    bytes4 callbackFunctionId;
    uint256 expiration;
    bytes data;
}

// Create a struct with any data you would like to use in the shouldRespond function
struct CollectOutput {
    AnswerUpdatedEvent[] answerUpdatedEvents;
    NewRoundEvent[] newRoundEvents;
    RoundRequestedEvent[] roundRequestedEvents;
    RoundAnsweredEvent[] roundAnsweredEvents;
    OracleRequestEvent[] oracleRequestEvents;
    OracleResponseEvent[] oracleResponseEvents;
    ChainlinkRequestedEvent[] chainlinkRequestedEvents;
    ChainlinkFulfilledEvent[] chainlinkFulfilledEvents;
    uint256 totalPriceUpdates;
    uint256 totalRounds;
    uint256 totalRequests;
    uint256 totalResponses;
    uint256 latestPrice;
    uint256 latestRoundId;
    uint256 latestTimestamp;
}

contract ChainlinkTrap is Trap {
    using EventFilterLib for EventFilter;

    address public immutable priceFeed = address(0x0000000000000000000000000000000000000000); // Chainlink Price Feed
    address public immutable oracleAddress = address(0x0000000000000000000000000000000000000000); // Chainlink Oracle

    function collect() external view override returns (bytes memory) {
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        (
            uint256 answerUpdatedCount,
            uint256 newRoundCount,
            uint256 roundRequestedCount,
            uint256 roundAnsweredCount,
            uint256 oracleRequestCount,
            uint256 oracleResponseCount,
            uint256 chainlinkRequestedCount,
            uint256 chainlinkFulfilledCount
        ) = _countEvents(logs, filters);

        AnswerUpdatedEvent[] memory answerUpdatedEvents = new AnswerUpdatedEvent[](answerUpdatedCount);
        NewRoundEvent[] memory newRoundEvents = new NewRoundEvent[](newRoundCount);
        RoundRequestedEvent[] memory roundRequestedEvents = new RoundRequestedEvent[](roundRequestedCount);
        RoundAnsweredEvent[] memory roundAnsweredEvents = new RoundAnsweredEvent[](roundAnsweredCount);
        OracleRequestEvent[] memory oracleRequestEvents = new OracleRequestEvent[](oracleRequestCount);
        OracleResponseEvent[] memory oracleResponseEvents = new OracleResponseEvent[](oracleResponseCount);
        ChainlinkRequestedEvent[] memory chainlinkRequestedEvents =
            new ChainlinkRequestedEvent[](chainlinkRequestedCount);
        ChainlinkFulfilledEvent[] memory chainlinkFulfilledEvents =
            new ChainlinkFulfilledEvent[](chainlinkFulfilledCount);

        (
            uint256 totalPriceUpdates,
            uint256 totalRounds,
            uint256 totalRequests,
            uint256 totalResponses,
            uint256 latestPrice,
            uint256 latestRoundId,
            uint256 latestTimestamp
        ) = _parseEvents(
            logs,
            filters,
            answerUpdatedEvents,
            newRoundEvents,
            roundRequestedEvents,
            roundAnsweredEvents,
            oracleRequestEvents,
            oracleResponseEvents,
            chainlinkRequestedEvents,
            chainlinkFulfilledEvents
        );

        return abi.encode(
            CollectOutput({
                answerUpdatedEvents: answerUpdatedEvents,
                newRoundEvents: newRoundEvents,
                roundRequestedEvents: roundRequestedEvents,
                roundAnsweredEvents: roundAnsweredEvents,
                oracleRequestEvents: oracleRequestEvents,
                oracleResponseEvents: oracleResponseEvents,
                chainlinkRequestedEvents: chainlinkRequestedEvents,
                chainlinkFulfilledEvents: chainlinkFulfilledEvents,
                totalPriceUpdates: totalPriceUpdates,
                totalRounds: totalRounds,
                totalRequests: totalRequests,
                totalResponses: totalResponses,
                latestPrice: latestPrice,
                latestRoundId: latestRoundId,
                latestTimestamp: latestTimestamp
            })
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));
        // loop through the data you have collected and check for anomalies
        // e.g., price feed staleness, large price deviations, oracle failures
        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](8);

        filters[0] = EventFilter({contractAddress: priceFeed, signature: "AnswerUpdated(int256,uint256,uint256)"});

        filters[1] = EventFilter({contractAddress: oracleAddress, signature: "NewRound(uint256,address,uint256)"});

        filters[2] = EventFilter({contractAddress: oracleAddress, signature: "RoundRequested(address,uint256,uint256)"});

        filters[3] = EventFilter({contractAddress: oracleAddress, signature: "RoundAnswered(uint256,address,uint256)"});

        filters[4] = EventFilter({
            contractAddress: oracleAddress,
            signature: "OracleRequest(bytes32,address,bytes32,uint256,address,bytes4,uint256,uint256,bytes)"
        });

        filters[5] = EventFilter({
            contractAddress: oracleAddress,
            signature: "OracleResponse(bytes32,address,bytes32,address,bytes4,uint256,bytes)"
        });

        filters[6] = EventFilter({
            contractAddress: oracleAddress,
            signature: "ChainlinkRequested(bytes32,address,bytes32,uint256,address,bytes4,uint256,uint256,bytes)"
        });

        filters[7] = EventFilter({
            contractAddress: oracleAddress,
            signature: "ChainlinkFulfilled(bytes32,uint256,address,bytes4,uint256,bytes)"
        });

        return filters;
    }

    function _countEvents(EventLog[] memory logs, EventFilter[] memory filters)
        internal
        pure
        returns (
            uint256 answerUpdatedCount,
            uint256 newRoundCount,
            uint256 roundRequestedCount,
            uint256 roundAnsweredCount,
            uint256 oracleRequestCount,
            uint256 oracleResponseCount,
            uint256 chainlinkRequestedCount,
            uint256 chainlinkFulfilledCount
        )
    {
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                answerUpdatedCount++;
            }
            if (filters[1].matches(log)) {
                newRoundCount++;
            }
            if (filters[2].matches(log)) {
                roundRequestedCount++;
            }
            if (filters[3].matches(log)) {
                roundAnsweredCount++;
            }
            if (filters[4].matches(log)) {
                oracleRequestCount++;
            }
            if (filters[5].matches(log)) {
                oracleResponseCount++;
            }
            if (filters[6].matches(log)) {
                chainlinkRequestedCount++;
            }
            if (filters[7].matches(log)) {
                chainlinkFulfilledCount++;
            }
        }
    }

    function _parseEvents(
        EventLog[] memory logs,
        EventFilter[] memory filters,
        AnswerUpdatedEvent[] memory answerUpdatedEvents,
        NewRoundEvent[] memory newRoundEvents,
        RoundRequestedEvent[] memory roundRequestedEvents,
        RoundAnsweredEvent[] memory roundAnsweredEvents,
        OracleRequestEvent[] memory oracleRequestEvents,
        OracleResponseEvent[] memory oracleResponseEvents,
        ChainlinkRequestedEvent[] memory chainlinkRequestedEvents,
        ChainlinkFulfilledEvent[] memory chainlinkFulfilledEvents
    )
        internal
        pure
        returns (
            uint256 totalPriceUpdates,
            uint256 totalRounds,
            uint256 totalRequests,
            uint256 totalResponses,
            uint256 latestPrice,
            uint256 latestRoundId,
            uint256 latestTimestamp
        )
    {
        uint256 answerUpdatedIndex = 0;
        uint256 newRoundIndex = 0;
        uint256 roundRequestedIndex = 0;
        uint256 roundAnsweredIndex = 0;
        uint256 oracleRequestIndex = 0;
        uint256 oracleResponseIndex = 0;
        uint256 chainlinkRequestedIndex = 0;
        uint256 chainlinkFulfilledIndex = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                answerUpdatedEvents[answerUpdatedIndex] = _parseAnswerUpdatedEvent(log);
                latestPrice = uint256(answerUpdatedEvents[answerUpdatedIndex].current);
                latestRoundId = answerUpdatedEvents[answerUpdatedIndex].roundId;
                latestTimestamp = answerUpdatedEvents[answerUpdatedIndex].updatedAt;
                totalPriceUpdates++;
                answerUpdatedIndex++;
            }
            if (filters[1].matches(log)) {
                newRoundEvents[newRoundIndex] = _parseNewRoundEvent(log);
                totalRounds++;
                newRoundIndex++;
            }
            if (filters[2].matches(log)) {
                roundRequestedEvents[roundRequestedIndex] = _parseRoundRequestedEvent(log);
                totalRequests++;
                roundRequestedIndex++;
            }
            if (filters[3].matches(log)) {
                roundAnsweredEvents[roundAnsweredIndex] = _parseRoundAnsweredEvent(log);
                totalResponses++;
                roundAnsweredIndex++;
            }
            if (filters[4].matches(log)) {
                oracleRequestEvents[oracleRequestIndex] = _parseOracleRequestEvent(log);
                totalRequests++;
                oracleRequestIndex++;
            }
            if (filters[5].matches(log)) {
                oracleResponseEvents[oracleResponseIndex] = _parseOracleResponseEvent(log);
                totalResponses++;
                oracleResponseIndex++;
            }
            if (filters[6].matches(log)) {
                chainlinkRequestedEvents[chainlinkRequestedIndex] = _parseChainlinkRequestedEvent(log);
                totalRequests++;
                chainlinkRequestedIndex++;
            }
            if (filters[7].matches(log)) {
                chainlinkFulfilledEvents[chainlinkFulfilledIndex] = _parseChainlinkFulfilledEvent(log);
                totalResponses++;
                chainlinkFulfilledIndex++;
            }
        }
    }

    function _parseAnswerUpdatedEvent(EventLog memory log)
        internal
        pure
        returns (AnswerUpdatedEvent memory answerUpdatedEvent)
    {
        int256 current = int256(uint256(log.topics[1]));
        uint256 roundId = uint256(log.topics[2]);

        (uint256 updatedAt) = abi.decode(log.data, (uint256));

        answerUpdatedEvent = AnswerUpdatedEvent({current: current, roundId: roundId, updatedAt: updatedAt});
    }

    function _parseNewRoundEvent(EventLog memory log) internal pure returns (NewRoundEvent memory newRoundEvent) {
        uint256 roundId = uint256(log.topics[1]);
        address startedBy = address(uint160(uint256(log.topics[2])));

        (uint256 startedAt) = abi.decode(log.data, (uint256));

        newRoundEvent = NewRoundEvent({roundId: roundId, startedBy: startedBy, startedAt: startedAt});
    }

    function _parseRoundRequestedEvent(EventLog memory log)
        internal
        pure
        returns (RoundRequestedEvent memory roundRequestedEvent)
    {
        address requester = address(uint160(uint256(log.topics[1])));
        uint256 roundId = uint256(log.topics[2]);

        (uint256 timestamp) = abi.decode(log.data, (uint256));

        roundRequestedEvent = RoundRequestedEvent({requester: requester, roundId: roundId, timestamp: timestamp});
    }

    function _parseRoundAnsweredEvent(EventLog memory log)
        internal
        pure
        returns (RoundAnsweredEvent memory roundAnsweredEvent)
    {
        uint256 roundId = uint256(log.topics[1]);
        address answerer = address(uint160(uint256(log.topics[2])));

        (uint256 timestamp) = abi.decode(log.data, (uint256));

        roundAnsweredEvent = RoundAnsweredEvent({roundId: roundId, answerer: answerer, timestamp: timestamp});
    }

    function _parseOracleRequestEvent(EventLog memory log)
        internal
        pure
        returns (OracleRequestEvent memory oracleRequestEvent)
    {
        bytes32 specId = log.topics[1];
        address requester = address(uint160(uint256(log.topics[2])));
        bytes32 requestId = log.topics[3];

        (
            uint256 payment,
            address callbackAddr,
            bytes4 callbackFunctionId,
            uint256 cancelExpiration,
            uint256 dataVersion,
            bytes memory data
        ) = abi.decode(log.data, (uint256, address, bytes4, uint256, uint256, bytes));

        oracleRequestEvent = OracleRequestEvent({
            specId: specId,
            requester: requester,
            requestId: requestId,
            payment: payment,
            callbackAddr: callbackAddr,
            callbackFunctionId: callbackFunctionId,
            cancelExpiration: cancelExpiration,
            dataVersion: dataVersion,
            data: data
        });
    }

    function _parseOracleResponseEvent(EventLog memory log)
        internal
        pure
        returns (OracleResponseEvent memory oracleResponseEvent)
    {
        bytes32 requestId = log.topics[1];
        address requester = address(uint160(uint256(log.topics[2])));
        bytes32 specId = log.topics[3];

        (address oracle, bytes4 callbackFunctionId, uint256 expiration, bytes memory data) =
            abi.decode(log.data, (address, bytes4, uint256, bytes));

        oracleResponseEvent = OracleResponseEvent({
            requestId: requestId,
            requester: requester,
            specId: specId,
            oracle: oracle,
            callbackFunctionId: callbackFunctionId,
            expiration: expiration,
            data: data
        });
    }

    function _parseChainlinkRequestedEvent(EventLog memory log)
        internal
        pure
        returns (ChainlinkRequestedEvent memory chainlinkRequestedEvent)
    {
        bytes32 specId = log.topics[1];
        address requester = address(uint160(uint256(log.topics[2])));
        bytes32 requestId = log.topics[3];

        (
            uint256 payment,
            address callbackAddr,
            bytes4 callbackFunctionId,
            uint256 cancelExpiration,
            uint256 dataVersion,
            bytes memory data
        ) = abi.decode(log.data, (uint256, address, bytes4, uint256, uint256, bytes));

        chainlinkRequestedEvent = ChainlinkRequestedEvent({
            specId: specId,
            requester: requester,
            requestId: requestId,
            payment: payment,
            callbackAddr: callbackAddr,
            callbackFunctionId: callbackFunctionId,
            cancelExpiration: cancelExpiration,
            dataVersion: dataVersion,
            data: data
        });
    }

    function _parseChainlinkFulfilledEvent(EventLog memory log)
        internal
        pure
        returns (ChainlinkFulfilledEvent memory chainlinkFulfilledEvent)
    {
        bytes32 requestId = log.topics[1];

        (uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 expiration, bytes memory data) =
            abi.decode(log.data, (uint256, address, bytes4, uint256, bytes));

        chainlinkFulfilledEvent = ChainlinkFulfilledEvent({
            requestId: requestId,
            payment: payment,
            callbackAddr: callbackAddr,
            callbackFunctionId: callbackFunctionId,
            expiration: expiration,
            data: data
        });
    }
}
