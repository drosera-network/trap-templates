// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";

struct SupplyEvent {
    address reserve;
    address user;
    address onBehalfOf;
    uint256 amount;
    uint16 referral;
}

struct BorrowEvent {
    address reserve;
    address user;
    address onBehalfOf;
    uint256 amount;
    uint8 interestRateMode;
    uint256 borrowRate;
    uint16 referral;
}

struct RepayEvent {
    address reserve;
    address user;
    address repayer;
    uint256 amount;
    bool useATokens;
}

struct LiquidationCallEvent {
    address collateralAsset;
    address debtAsset;
    address user;
    uint256 debtToCover;
    uint256 liquidatedCollateralAmount;
    address liquidator;
    bool receiveAToken;
}

struct FlashLoanEvent {
    address receiver;
    address asset;
    uint256 amount;
    uint256 premium;
    uint16 referralCode;
}

struct ReserveDataUpdatedEvent {
    address asset;
    uint256 liquidityRate;
    uint256 variableBorrowRate;
    uint256 liquidityIndex;
    uint256 variableBorrowIndex;
}

struct ReserveUsedAsCollateralEvent {
    address reserve;
    address user;
    bool enabled;
}

struct SwapEvent {
    address reserve;
    address user;
    uint256 rateMode;
}

// Create a struct with any data you would like to use in the shouldRespond function
struct CollectOutput {
    SupplyEvent[] supplyEvents;
    BorrowEvent[] borrowEvents;
    RepayEvent[] repayEvents;
    LiquidationCallEvent[] liquidationEvents;
    FlashLoanEvent[] flashLoanEvents;
    ReserveDataUpdatedEvent[] reserveUpdateEvents;
    ReserveUsedAsCollateralEvent[] collateralEvents;
    SwapEvent[] swapEvents;
    uint256 totalSupplyVolume;
    uint256 totalBorrowVolume;
    uint256 totalRepayVolume;
    uint256 totalLiquidationVolume;
    uint256 totalFlashLoanVolume;
}

contract AaveTrap is Trap {
    using EventFilterLib for EventFilter;

    address public lendingPool; // Aave Lending Pool

    function collect() external view override returns (bytes memory) {
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        (
            uint256 supplyCount,
            uint256 borrowCount,
            uint256 repayCount,
            uint256 liquidationCount,
            uint256 flashLoanCount,
            uint256 reserveUpdateCount,
            uint256 collateralCount,
            uint256 swapCount
        ) = _countEvents(logs, filters);

        SupplyEvent[] memory supplyEvents = new SupplyEvent[](supplyCount);
        BorrowEvent[] memory borrowEvents = new BorrowEvent[](borrowCount);
        RepayEvent[] memory repayEvents = new RepayEvent[](repayCount);
        LiquidationCallEvent[] memory liquidationEvents = new LiquidationCallEvent[](liquidationCount);
        FlashLoanEvent[] memory flashLoanEvents = new FlashLoanEvent[](flashLoanCount);
        ReserveDataUpdatedEvent[] memory reserveUpdateEvents = new ReserveDataUpdatedEvent[](reserveUpdateCount);
        ReserveUsedAsCollateralEvent[] memory collateralEvents = new ReserveUsedAsCollateralEvent[](collateralCount);
        SwapEvent[] memory swapEvents = new SwapEvent[](swapCount);

        
        (
            uint256 totalSupplyVolume,
            uint256 totalBorrowVolume,
            uint256 totalRepayVolume,
            uint256 totalLiquidationVolume,
            uint256 totalFlashLoanVolume
        ) = _parseEvents(
            logs,
            filters,
            supplyEvents,
            borrowEvents,
            repayEvents,
            liquidationEvents,
            flashLoanEvents,
            reserveUpdateEvents,
            collateralEvents,
            swapEvents
        );

        return abi.encode(
            CollectOutput({
                supplyEvents: supplyEvents,
                borrowEvents: borrowEvents,
                repayEvents: repayEvents,
                liquidationEvents: liquidationEvents,
                flashLoanEvents: flashLoanEvents,
                reserveUpdateEvents: reserveUpdateEvents,
                collateralEvents: collateralEvents,
                swapEvents: swapEvents,
                totalSupplyVolume: totalSupplyVolume,
                totalBorrowVolume: totalBorrowVolume,
                totalRepayVolume: totalRepayVolume,
                totalLiquidationVolume: totalLiquidationVolume,
                totalFlashLoanVolume: totalFlashLoanVolume
            })
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));
        //Example: Watch for supply events over a certain amount
        if (currOutput.supplyEvents.length > 0) {
            for (uint256 i = 0; i < currOutput.supplyEvents.length; i++) {
                if (currOutput.supplyEvents[i].amount > 10000000) {
                        return (true, "");
                    }
                }
        }

        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](8);

        filters[0] =
            EventFilter({contractAddress: lendingPool, signature: "Supply(address,address,address,uint256,uint16)"});

        filters[1] = EventFilter({
            contractAddress: lendingPool,
            signature: "Borrow(address,address,address,uint256,uint8,uint256,uint16)"
        });

        filters[2] =
            EventFilter({contractAddress: lendingPool, signature: "Repay(address,address,address,uint256,bool)"});

        filters[3] = EventFilter({
            contractAddress: lendingPool,
            signature: "LiquidationCall(address,address,address,uint256,uint256,address,bool)"
        });

        filters[4] =
            EventFilter({contractAddress: lendingPool, signature: "FlashLoan(address,address,uint256,uint256,uint16)"});

        filters[5] = EventFilter({
            contractAddress: lendingPool,
            signature: "ReserveDataUpdated(address,uint256,uint256,uint256,uint256)"
        });

        filters[6] =
            EventFilter({contractAddress: lendingPool, signature: "ReserveUsedAsCollateralEnabled(address,address)"});

        filters[7] = EventFilter({contractAddress: lendingPool, signature: "Swap(address,address,uint256)"});

        return filters;
    }

    function _countEvents(EventLog[] memory logs, EventFilter[] memory filters)
        internal
        pure
        returns (
            uint256 supplyCount,
            uint256 borrowCount,
            uint256 repayCount,
            uint256 liquidationCount,
            uint256 flashLoanCount,
            uint256 reserveUpdateCount,
            uint256 collateralCount,
            uint256 swapCount
        )
    {
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                supplyCount++;
            }
            if (filters[1].matches(log)) {
                borrowCount++;
            }
            if (filters[2].matches(log)) {
                repayCount++;
            }
            if (filters[3].matches(log)) {
                liquidationCount++;
            }
            if (filters[4].matches(log)) {
                flashLoanCount++;
            }
            if (filters[5].matches(log)) {
                reserveUpdateCount++;
            }
            if (filters[6].matches(log)) {
                collateralCount++;
            }
            if (filters[7].matches(log)) {
                swapCount++;
            }
        }
    }

    function _parseEvents(
        EventLog[] memory logs,
        EventFilter[] memory filters,
        SupplyEvent[] memory supplyEvents,
        BorrowEvent[] memory borrowEvents,
        RepayEvent[] memory repayEvents,
        LiquidationCallEvent[] memory liquidationEvents,
        FlashLoanEvent[] memory flashLoanEvents,
        ReserveDataUpdatedEvent[] memory reserveUpdateEvents,
        ReserveUsedAsCollateralEvent[] memory collateralEvents,
        SwapEvent[] memory swapEvents
    )
        internal
        view
        returns (
            uint256 totalSupplyVolume,
            uint256 totalBorrowVolume,
            uint256 totalRepayVolume,
            uint256 totalLiquidationVolume,
            uint256 totalFlashLoanVolume
        )
    {
        uint256 supplyIndex = 0;
        uint256 borrowIndex = 0;
        uint256 repayIndex = 0;
        uint256 liquidationIndex = 0;
        uint256 flashLoanIndex = 0;
        uint256 reserveUpdateIndex = 0;
        uint256 collateralIndex = 0;
        uint256 swapIndex = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                supplyEvents[supplyIndex] = _parseSupplyEvent(log);
                totalSupplyVolume += supplyEvents[supplyIndex].amount;
                supplyIndex++;
            }
            if (filters[1].matches(log)) {
                borrowEvents[borrowIndex] = _parseBorrowEvent(log);
                totalBorrowVolume += borrowEvents[borrowIndex].amount;
                borrowIndex++;
            }
            if (filters[2].matches(log)) {
                repayEvents[repayIndex] = _parseRepayEvent(log);
                totalRepayVolume += repayEvents[repayIndex].amount;
                repayIndex++;
            }
            if (filters[3].matches(log)) {
                liquidationEvents[liquidationIndex] = _parseLiquidationEvent(log);
                totalLiquidationVolume += liquidationEvents[liquidationIndex].debtToCover;
                liquidationIndex++;
            }
            if (filters[4].matches(log)) {
                flashLoanEvents[flashLoanIndex] = _parseFlashLoanEvent(log);
                totalFlashLoanVolume += flashLoanEvents[flashLoanIndex].amount;
                flashLoanIndex++;
            }
            if (filters[5].matches(log)) {
                reserveUpdateEvents[reserveUpdateIndex] = _parseReserveDataUpdatedEvent(log);
                reserveUpdateIndex++;
            }
            if (filters[6].matches(log)) {
                collateralEvents[collateralIndex] = _parseReserveUsedAsCollateralEvent(log);
                collateralIndex++;
            }
            if (filters[7].matches(log)) {
                swapEvents[swapIndex] = _parseSwapEvent(log);
                swapIndex++;
            }
        }
    }

    function _parseSupplyEvent(EventLog memory log) internal pure returns (SupplyEvent memory supplyEvent) {
        address reserve = address(uint160(uint256(log.topics[1])));
        uint16 referralCode = uint16(uint256(log.topics[3]));
        address onBehalfOf = address(uint160(uint256(log.topics[2])));

        (address user, uint256 amount) = abi.decode(log.data, (address, uint256));

        supplyEvent =
            SupplyEvent({reserve: reserve, user: user, onBehalfOf: onBehalfOf, amount: amount, referral: referralCode});
    }

    function _parseBorrowEvent(EventLog memory log) internal pure returns (BorrowEvent memory borrowEvent) {
        address reserve = address(uint160(uint256(log.topics[1])));
        address user = address(uint160(uint256(log.topics[2])));
        address onBehalfOf = address(uint160(uint256(log.topics[3])));

        (uint256 amount, uint8 interestRateMode, uint256 borrowRate, uint16 referral) =
            abi.decode(log.data, (uint256, uint8, uint256, uint16));

        borrowEvent = BorrowEvent({
            reserve: reserve,
            user: user,
            onBehalfOf: onBehalfOf,
            amount: amount,
            interestRateMode: interestRateMode,
            borrowRate: borrowRate,
            referral: referral
        });
    }

    function _parseRepayEvent(EventLog memory log) internal pure returns (RepayEvent memory repayEvent) {
        address reserve = address(uint160(uint256(log.topics[1])));
        address user = address(uint160(uint256(log.topics[2])));
        address repayer = address(uint160(uint256(log.topics[3])));

        (uint256 amount, bool useATokens) = abi.decode(log.data, (uint256, bool));

        repayEvent =
            RepayEvent({reserve: reserve, user: user, repayer: repayer, amount: amount, useATokens: useATokens});
    }

    function _parseLiquidationEvent(EventLog memory log)
        internal
        pure
        returns (LiquidationCallEvent memory liquidationEvent)
    {
        address collateralAsset = address(uint160(uint256(log.topics[1])));
        address debtAsset = address(uint160(uint256(log.topics[2])));
        address user = address(uint160(uint256(log.topics[3])));

        (uint256 debtToCover, uint256 liquidatedCollateralAmount, address liquidator, bool receiveAToken) =
            abi.decode(log.data, (uint256, uint256, address, bool));

        liquidationEvent = LiquidationCallEvent({
            collateralAsset: collateralAsset,
            debtAsset: debtAsset,
            user: user,
            debtToCover: debtToCover,
            liquidatedCollateralAmount: liquidatedCollateralAmount,
            liquidator: liquidator,
            receiveAToken: receiveAToken
        });
    }

    function _parseFlashLoanEvent(EventLog memory log) internal pure returns (FlashLoanEvent memory flashLoanEvent) {
        address receiver = address(uint160(uint256(log.topics[1])));
        address asset = address(uint160(uint256(log.topics[2])));

        (uint256 amount, uint256 premium, uint16 referralCode) = abi.decode(log.data, (uint256, uint256, uint16));

        flashLoanEvent = FlashLoanEvent({
            receiver: receiver,
            asset: asset,
            amount: amount,
            premium: premium,
            referralCode: referralCode
        });
    }

    function _parseReserveDataUpdatedEvent(EventLog memory log)
        internal
        pure
        returns (ReserveDataUpdatedEvent memory reserveUpdateEvent)
    {
        address asset = address(uint160(uint256(log.topics[1])));

        (uint256 liquidityRate, uint256 variableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex) =
            abi.decode(log.data, (uint256, uint256, uint256, uint256));

        reserveUpdateEvent = ReserveDataUpdatedEvent({
            asset: asset,
            liquidityRate: liquidityRate,
            variableBorrowRate: variableBorrowRate,
            liquidityIndex: liquidityIndex,
            variableBorrowIndex: variableBorrowIndex
        });
    }

    function _parseReserveUsedAsCollateralEvent(EventLog memory log)
        internal
        pure
        returns (ReserveUsedAsCollateralEvent memory collateralEvent)
    {
        address reserve = address(uint160(uint256(log.topics[1])));
        address user = address(uint160(uint256(log.topics[2])));

        collateralEvent = ReserveUsedAsCollateralEvent({
            reserve: reserve,
            user: user,
            enabled: true // This event is for enabling collateral
        });
    }

    function _parseSwapEvent(EventLog memory log) internal pure returns (SwapEvent memory swapEvent) {
        address reserve = address(uint160(uint256(log.topics[1])));
        address user = address(uint160(uint256(log.topics[2])));

        (uint256 rateMode) = abi.decode(log.data, (uint256));

        swapEvent = SwapEvent({reserve: reserve, user: user, rateMode: rateMode});
    }

    // Used for testing
    function setupTest(address _lendingPool) external {
        lendingPool = _lendingPool;
    }
}
