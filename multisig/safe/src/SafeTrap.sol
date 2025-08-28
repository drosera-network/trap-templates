// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";

struct ExecutionSuccessEvent {
    bytes32 txHash;
    uint256 payment;
}

struct ExecutionFailureEvent {
    bytes32 txHash;
    uint256 payment;
}

struct AddedOwnerEvent {
    address owner;
}

struct RemovedOwnerEvent {
    address owner;
}

struct ChangedThresholdEvent {
    uint256 threshold;
}

struct EnabledModuleEvent {
    address module;
}

struct DisabledModuleEvent {
    address module;
}

struct SafeSetupEvent {
    address initiator;
    address[] owners;
    uint256 threshold;
    address fallbackHandler;
    address initializer;
}

struct SafeReceivedEvent {
    address sender;
    uint256 value;
}

struct ChangedGuardEvent {
    address guard;
}

struct ExecutionFromModuleSuccessEvent {
    address module;
}

struct ExecutionFromModuleFailureEvent {
    address module;
    bytes32 txHash;
    uint256 payment;
}

struct SafeMultiSigTransactionEvent {
    address to;
    uint256 value;
    bytes data;
    Operation operation;
    uint256 safeTxGas;
    uint256 baseGas;
    uint256 gasPrice;
    address gasToken;
    address refundReceiver;
    bytes signatures;
    bytes additionalInfo;
}

struct SafeModuleTransactionEvent {
    address module;
    address to;
    uint256 value;
    bytes data;
    Operation operation;
}

// Create a struct with any data you would like to use in the shouldRespond function
struct CollectOutput {
    ExecutionSuccessEvent[] executionSuccessEvents;
    ExecutionFailureEvent[] executionFailureEvents;
    AddedOwnerEvent[] addedOwnerEvents;
    RemovedOwnerEvent[] removedOwnerEvents;
    ChangedThresholdEvent[] changedThresholdEvents;
    EnabledModuleEvent[] enabledModuleEvents;
    DisabledModuleEvent[] disabledModuleEvents;
    SafeSetupEvent[] safeSetupEvents;
    SafeReceivedEvent[] safeReceivedEvents;
    ChangedGuardEvent[] changedGuardEvents;
    ExecutionFromModuleSuccessEvent[] executionFromModuleSuccessEvents;
    ExecutionFromModuleFailureEvent[] executionFromModuleFailureEvents;
    SafeMultiSigTransactionEvent[] safeMultiSigTransactionEvents;
    SafeModuleTransactionEvent[] safeModuleTransactionEvents;
    uint256 totalExecutions;
    uint256 totalFailures;
    uint256 totalOwnerChanges;
    uint256 totalThresholdChanges;
    uint256 totalModuleChanges;
    uint256 totalReceived;
    uint256 totalGuardChanges;
    uint256 totalModuleExecutions;
    uint256 totalMultiSigTransactions;
    uint256 totalModuleTransactions;
}

enum Operation {
    Call,
    DelegateCall
}

contract SafeTrap is Trap {
    using EventFilterLib for EventFilter;

    address public immutable safe = address(0x0000000000000000000000000000000000000000); // Safe multisig wallet

    function collect() external view override returns (bytes memory) {
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        (
            uint256 executionSuccessCount,
            uint256 executionFailureCount,
            uint256 addedOwnerCount,
            uint256 removedOwnerCount,
            uint256 changedThresholdCount,
            uint256 enabledModuleCount,
            uint256 disabledModuleCount,
            uint256 safeSetupCount,
            uint256 safeReceivedCount,
            uint256 changedGuardCount,
            uint256 executionFromModuleSuccessCount,
            uint256 executionFromModuleFailureCount,
            uint256 safeMultiSigTransactionCount,
            uint256 safeModuleTransactionCount
        ) = _countEvents(logs, filters);

        ExecutionSuccessEvent[] memory executionSuccessEvents = new ExecutionSuccessEvent[](executionSuccessCount);
        ExecutionFailureEvent[] memory executionFailureEvents = new ExecutionFailureEvent[](executionFailureCount);
        AddedOwnerEvent[] memory addedOwnerEvents = new AddedOwnerEvent[](addedOwnerCount);
        RemovedOwnerEvent[] memory removedOwnerEvents = new RemovedOwnerEvent[](removedOwnerCount);
        ChangedThresholdEvent[] memory changedThresholdEvents = new ChangedThresholdEvent[](changedThresholdCount);
        EnabledModuleEvent[] memory enabledModuleEvents = new EnabledModuleEvent[](enabledModuleCount);
        DisabledModuleEvent[] memory disabledModuleEvents = new DisabledModuleEvent[](disabledModuleCount);
        SafeSetupEvent[] memory safeSetupEvents = new SafeSetupEvent[](safeSetupCount);
        SafeReceivedEvent[] memory safeReceivedEvents = new SafeReceivedEvent[](safeReceivedCount);
        ChangedGuardEvent[] memory changedGuardEvents = new ChangedGuardEvent[](changedGuardCount);
        ExecutionFromModuleSuccessEvent[] memory executionFromModuleSuccessEvents =
            new ExecutionFromModuleSuccessEvent[](executionFromModuleSuccessCount);
        ExecutionFromModuleFailureEvent[] memory executionFromModuleFailureEvents =
            new ExecutionFromModuleFailureEvent[](executionFromModuleFailureCount);
        SafeMultiSigTransactionEvent[] memory safeMultiSigTransactionEvents =
            new SafeMultiSigTransactionEvent[](safeMultiSigTransactionCount);
        SafeModuleTransactionEvent[] memory safeModuleTransactionEvents =
            new SafeModuleTransactionEvent[](safeModuleTransactionCount);

        (
            uint256 totalExecutions,
            uint256 totalFailures,
            uint256 totalOwnerChanges,
            uint256 totalThresholdChanges,
            uint256 totalModuleChanges,
            uint256 totalReceived,
            uint256 totalGuardChanges,
            uint256 totalModuleExecutions,
            uint256 totalMultiSigTransactions,
            uint256 totalModuleTransactions
        ) = _parseEvents(
            logs,
            filters,
            executionSuccessEvents,
            executionFailureEvents,
            addedOwnerEvents,
            removedOwnerEvents,
            changedThresholdEvents,
            enabledModuleEvents,
            disabledModuleEvents,
            safeSetupEvents,
            safeReceivedEvents,
            changedGuardEvents,
            executionFromModuleSuccessEvents,
            executionFromModuleFailureEvents,
            safeMultiSigTransactionEvents,
            safeModuleTransactionEvents
        );

        return abi.encode(
            CollectOutput({
                executionSuccessEvents: executionSuccessEvents,
                executionFailureEvents: executionFailureEvents,
                addedOwnerEvents: addedOwnerEvents,
                removedOwnerEvents: removedOwnerEvents,
                changedThresholdEvents: changedThresholdEvents,
                enabledModuleEvents: enabledModuleEvents,
                disabledModuleEvents: disabledModuleEvents,
                safeSetupEvents: safeSetupEvents,
                safeReceivedEvents: safeReceivedEvents,
                changedGuardEvents: changedGuardEvents,
                executionFromModuleSuccessEvents: executionFromModuleSuccessEvents,
                executionFromModuleFailureEvents: executionFromModuleFailureEvents,
                safeMultiSigTransactionEvents: safeMultiSigTransactionEvents,
                safeModuleTransactionEvents: safeModuleTransactionEvents,
                totalExecutions: totalExecutions,
                totalFailures: totalFailures,
                totalOwnerChanges: totalOwnerChanges,
                totalThresholdChanges: totalThresholdChanges,
                totalModuleChanges: totalModuleChanges,
                totalReceived: totalReceived,
                totalGuardChanges: totalGuardChanges,
                totalModuleExecutions: totalModuleExecutions,
                totalMultiSigTransactions: totalMultiSigTransactions,
                totalModuleTransactions: totalModuleTransactions
            })
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));
        // loop through the data you have collected and check for anomalies
        // e.g., unusual owner changes, threshold modifications, failed executions
        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](15);

        filters[0] = EventFilter({contractAddress: safe, signature: "ExecutionSuccess(bytes32,uint256)"});

        filters[1] = EventFilter({contractAddress: safe, signature: "ExecutionFailure(bytes32,uint256)"});

        filters[2] = EventFilter({contractAddress: safe, signature: "AddedOwner(address)"});

        filters[3] = EventFilter({contractAddress: safe, signature: "RemovedOwner(address)"});

        filters[4] = EventFilter({contractAddress: safe, signature: "ChangedThreshold(uint256)"});

        filters[5] = EventFilter({contractAddress: safe, signature: "EnabledModule(address)"});

        filters[6] = EventFilter({contractAddress: safe, signature: "DisabledModule(address)"});

        filters[7] =
            EventFilter({contractAddress: safe, signature: "SafeSetup(address,address[],uint256,address,address)"});

        filters[8] = EventFilter({contractAddress: safe, signature: "SafeReceived(address,uint256)"});

        filters[9] = EventFilter({contractAddress: safe, signature: "ChangedGuard(address)"});

        filters[10] = EventFilter({contractAddress: safe, signature: "ExecutionFromModuleSuccess(address)"});

        filters[11] = EventFilter({contractAddress: safe, signature: "ExecutionFromModuleFailure(address)"});

        filters[12] = EventFilter({
            contractAddress: safe,
            signature: "SafeMultiSigTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes,bytes)"
        });

        filters[13] = EventFilter({
            contractAddress: safe,
            signature: "SafeModuleTransaction(address,address,uint256,bytes,uint8)"
        });

        return filters;
    }

    function _countEvents(EventLog[] memory logs, EventFilter[] memory filters)
        internal
        pure
        returns (
            uint256 executionSuccessCount,
            uint256 executionFailureCount,
            uint256 addedOwnerCount,
            uint256 removedOwnerCount,
            uint256 changedThresholdCount,
            uint256 enabledModuleCount,
            uint256 disabledModuleCount,
            uint256 safeSetupCount,
            uint256 safeReceivedCount,
            uint256 changedGuardCount,
            uint256 executionFromModuleSuccessCount,
            uint256 executionFromModuleFailureCount,
            uint256 safeMultiSigTransactionCount,
            uint256 safeModuleTransactionCount
        )
    {
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                executionSuccessCount++;
            }
            if (filters[1].matches(log)) {
                executionFailureCount++;
            }
            if (filters[2].matches(log)) {
                addedOwnerCount++;
            }
            if (filters[3].matches(log)) {
                removedOwnerCount++;
            }
            if (filters[4].matches(log)) {
                changedThresholdCount++;
            }
            if (filters[5].matches(log)) {
                enabledModuleCount++;
            }
            if (filters[6].matches(log)) {
                disabledModuleCount++;
            }
            if (filters[7].matches(log)) {
                safeSetupCount++;
            }
            if (filters[8].matches(log)) {
                safeReceivedCount++;
            }
            if (filters[9].matches(log)) {
                changedGuardCount++;
            }
            if (filters[10].matches(log)) {
                executionFromModuleSuccessCount++;
            }
            if (filters[11].matches(log)) {
                executionFromModuleFailureCount++;
            }
            if (filters[12].matches(log)) {
                safeMultiSigTransactionCount++;
            }
            if (filters[13].matches(log)) {
                safeModuleTransactionCount++;
            }
        }
    }

    function _parseEvents(
        EventLog[] memory logs,
        EventFilter[] memory filters,
        ExecutionSuccessEvent[] memory executionSuccessEvents,
        ExecutionFailureEvent[] memory executionFailureEvents,
        AddedOwnerEvent[] memory addedOwnerEvents,
        RemovedOwnerEvent[] memory removedOwnerEvents,
        ChangedThresholdEvent[] memory changedThresholdEvents,
        EnabledModuleEvent[] memory enabledModuleEvents,
        DisabledModuleEvent[] memory disabledModuleEvents,
        SafeSetupEvent[] memory safeSetupEvents,
        SafeReceivedEvent[] memory safeReceivedEvents,
        ChangedGuardEvent[] memory changedGuardEvents,
        ExecutionFromModuleSuccessEvent[] memory executionFromModuleSuccessEvents,
        ExecutionFromModuleFailureEvent[] memory executionFromModuleFailureEvents,
        SafeMultiSigTransactionEvent[] memory safeMultiSigTransactionEvents,
        SafeModuleTransactionEvent[] memory safeModuleTransactionEvents
    )
        internal
        pure
        returns (
            uint256 totalExecutions,
            uint256 totalFailures,
            uint256 totalOwnerChanges,
            uint256 totalThresholdChanges,
            uint256 totalModuleChanges,
            uint256 totalReceived,
            uint256 totalGuardChanges,
            uint256 totalModuleExecutions,
            uint256 totalMultiSigTransactions,
            uint256 totalModuleTransactions
        )
    {
        uint256 executionSuccessIndex = 0;
        uint256 executionFailureIndex = 0;
        uint256 addedOwnerIndex = 0;
        uint256 removedOwnerIndex = 0;
        uint256 changedThresholdIndex = 0;
        uint256 enabledModuleIndex = 0;
        uint256 disabledModuleIndex = 0;
        uint256 safeSetupIndex = 0;
        uint256 safeReceivedIndex = 0;
        uint256 changedGuardIndex = 0;
        uint256 executionFromModuleSuccessIndex = 0;
        uint256 executionFromModuleFailureIndex = 0;
        uint256 safeMultiSigTransactionIndex = 0;
        uint256 safeModuleTransactionIndex = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                executionSuccessEvents[executionSuccessIndex] = _parseExecutionSuccessEvent(log);
                totalExecutions++;
                executionSuccessIndex++;
            }
            if (filters[1].matches(log)) {
                executionFailureEvents[executionFailureIndex] = _parseExecutionFailureEvent(log);
                totalFailures++;
                executionFailureIndex++;
            }
            if (filters[2].matches(log)) {
                addedOwnerEvents[addedOwnerIndex] = _parseAddedOwnerEvent(log);
                totalOwnerChanges++;
                addedOwnerIndex++;
            }
            if (filters[3].matches(log)) {
                removedOwnerEvents[removedOwnerIndex] = _parseRemovedOwnerEvent(log);
                totalOwnerChanges++;
                removedOwnerIndex++;
            }
            if (filters[4].matches(log)) {
                changedThresholdEvents[changedThresholdIndex] = _parseChangedThresholdEvent(log);
                totalThresholdChanges++;
                changedThresholdIndex++;
            }
            if (filters[5].matches(log)) {
                enabledModuleEvents[enabledModuleIndex] = _parseEnabledModuleEvent(log);
                totalModuleChanges++;
                enabledModuleIndex++;
            }
            if (filters[6].matches(log)) {
                disabledModuleEvents[disabledModuleIndex] = _parseDisabledModuleEvent(log);
                totalModuleChanges++;
                disabledModuleIndex++;
            }
            if (filters[7].matches(log)) {
                safeSetupEvents[safeSetupIndex] = _parseSafeSetupEvent(log);
                safeSetupIndex++;
            }
            if (filters[8].matches(log)) {
                safeReceivedEvents[safeReceivedIndex] = _parseSafeReceivedEvent(log);
                totalReceived++;
                safeReceivedIndex++;
            }
            if (filters[9].matches(log)) {
                changedGuardEvents[changedGuardIndex] = _parseChangedGuardEvent(log);
                totalGuardChanges++;
                changedGuardIndex++;
            }
            if (filters[10].matches(log)) {
                executionFromModuleSuccessEvents[executionFromModuleSuccessIndex] =
                    _parseExecutionFromModuleSuccessEvent(log);
                totalModuleExecutions++;
                executionFromModuleSuccessIndex++;
            }
            if (filters[11].matches(log)) {
                executionFromModuleFailureEvents[executionFromModuleFailureIndex] =
                    _parseExecutionFromModuleFailureEvent(log);
                totalModuleExecutions++;
                executionFromModuleFailureIndex++;
            }
            if (filters[12].matches(log)) {
                safeMultiSigTransactionEvents[safeMultiSigTransactionIndex] = _parseSafeMultiSigTransactionEvent(log);
                totalMultiSigTransactions++;
                safeMultiSigTransactionIndex++;
            }
            if (filters[13].matches(log)) {
                safeModuleTransactionEvents[safeModuleTransactionIndex] = _parseSafeModuleTransactionEvent(log);
                totalModuleTransactions++;
                safeModuleTransactionIndex++;
            }
        }

        return (
            totalExecutions,
            totalFailures,
            totalOwnerChanges,
            totalThresholdChanges,
            totalModuleChanges,
            totalReceived,
            totalGuardChanges,
            totalModuleExecutions,
            totalMultiSigTransactions,
            totalModuleTransactions
        );
    }

    function _parseExecutionSuccessEvent(EventLog memory log)
        internal
        pure
        returns (ExecutionSuccessEvent memory executionSuccessEvent)
    {
        bytes32 txHash = log.topics[1];
        (uint256 payment) = abi.decode(log.data, (uint256));

        executionSuccessEvent = ExecutionSuccessEvent({txHash: txHash, payment: payment});
    }

    function _parseExecutionFailureEvent(EventLog memory log)
        internal
        pure
        returns (ExecutionFailureEvent memory executionFailureEvent)
    {
        bytes32 txHash = log.topics[1];

        (uint256 payment) = abi.decode(log.data, (uint256));

        executionFailureEvent = ExecutionFailureEvent({txHash: txHash, payment: payment});
    }

    function _parseAddedOwnerEvent(EventLog memory log)
        internal
        pure
        returns (AddedOwnerEvent memory addedOwnerEvent)
    {
        (address owner) = abi.decode(log.data, (address));

        addedOwnerEvent = AddedOwnerEvent({owner: owner});
    }

    function _parseRemovedOwnerEvent(EventLog memory log)
        internal
        pure
        returns (RemovedOwnerEvent memory removedOwnerEvent)
    {
        (address owner) = abi.decode(log.data, (address));

        removedOwnerEvent = RemovedOwnerEvent({owner: owner});
    }

    function _parseChangedThresholdEvent(EventLog memory log)
        internal
        pure
        returns (ChangedThresholdEvent memory changedThresholdEvent)
    {
        (uint256 threshold) = abi.decode(log.data, (uint256));

        changedThresholdEvent = ChangedThresholdEvent({threshold: threshold});
    }

    function _parseEnabledModuleEvent(EventLog memory log)
        internal
        pure
        returns (EnabledModuleEvent memory enabledModuleEvent)
    {
        (address module) = abi.decode(log.data, (address));

        enabledModuleEvent = EnabledModuleEvent({module: module});
    }

    function _parseDisabledModuleEvent(EventLog memory log)
        internal
        pure
        returns (DisabledModuleEvent memory disabledModuleEvent)
    {
        (address module) = abi.decode(log.data, (address));

        disabledModuleEvent = DisabledModuleEvent({module: module});
    }

    function _parseSafeSetupEvent(EventLog memory log) internal pure returns (SafeSetupEvent memory safeSetupEvent) {
        address initiator = address(uint160(uint256(log.topics[1])));

        (address[] memory owners, uint256 threshold, address fallbackHandler, address initializer) =
            abi.decode(log.data, (address[], uint256, address, address));

        safeSetupEvent = SafeSetupEvent({
            initiator: initiator,
            owners: owners,
            threshold: threshold,
            fallbackHandler: fallbackHandler,
            initializer: initializer
        });
    }

    function _parseSafeReceivedEvent(EventLog memory log)
        internal
        pure
        returns (SafeReceivedEvent memory safeReceivedEvent)
    {
        address sender = address(uint160(uint256(log.topics[1])));

        (uint256 value) = abi.decode(log.data, (uint256));

        safeReceivedEvent = SafeReceivedEvent({sender: sender, value: value});
    }

    function _parseChangedGuardEvent(EventLog memory log)
        internal
        pure
        returns (ChangedGuardEvent memory changedGuardEvent)
    {
        (address guard) = abi.decode(log.data, (address));

        changedGuardEvent = ChangedGuardEvent({guard: guard});
    }

    function _parseExecutionFromModuleSuccessEvent(EventLog memory log)
        internal
        pure
        returns (ExecutionFromModuleSuccessEvent memory executionFromModuleSuccessEvent)
    {
        (address module) = abi.decode(log.data, (address));

        executionFromModuleSuccessEvent = ExecutionFromModuleSuccessEvent({module: module});
    }

    function _parseExecutionFromModuleFailureEvent(EventLog memory log)
        internal
        pure
        returns (ExecutionFromModuleFailureEvent memory executionFromModuleFailureEvent)
    {
        (address module) = abi.decode(log.data, (address));

        bytes32 txHash = log.topics[1];
        (uint256 payment) = abi.decode(log.data, (uint256));
        executionFromModuleFailureEvent =
            ExecutionFromModuleFailureEvent({module: module, txHash: txHash, payment: payment});
    }

    function _parseSafeMultiSigTransactionEvent(EventLog memory log)
        internal
        pure
        returns (SafeMultiSigTransactionEvent memory safeMultiSigTransactionEvent)
    {
        (
            address to,
            uint256 value,
            bytes memory data,
            uint8 operation,
            uint256 safeTxGas,
            uint256 baseGas,
            uint256 gasPrice,
            address gasToken,
            address refundReceiver,
            bytes memory signatures,
            bytes memory additionalInfo
        ) = abi.decode(
            log.data, (address, uint256, bytes, uint8, uint256, uint256, uint256, address, address, bytes, bytes)
        );

        safeMultiSigTransactionEvent = SafeMultiSigTransactionEvent({
            to: to,
            value: value,
            data: data,
            operation: Operation(operation),
            safeTxGas: safeTxGas,
            baseGas: baseGas,
            gasPrice: gasPrice,
            gasToken: gasToken,
            refundReceiver: refundReceiver,
            signatures: signatures,
            additionalInfo: additionalInfo
        });
    }

    function _parseSafeModuleTransactionEvent(EventLog memory log)
        internal
        pure
        returns (SafeModuleTransactionEvent memory safeModuleTransactionEvent)
    {
        (address module, address to, uint256 value, bytes memory data, uint8 operation) =
            abi.decode(log.data, (address, address, uint256, bytes, uint8));

        safeModuleTransactionEvent = SafeModuleTransactionEvent({
            module: module,
            to: to,
            value: value,
            data: data,
            operation: Operation(operation)
        });
    }

    function _getOwners() internal view returns (address[] memory) {
        return ISafe(safe).getOwners();
    }

    function _getThreshold() internal view returns (uint256) {
        return ISafe(safe).getThreshold();
    }

    function _getTransactionCount() internal view returns (uint256) {
        return ISafe(safe).getTransactionCount();
    }

    function _isOwner(address owner) internal view returns (bool) {
        return ISafe(safe).isOwner(owner);
    }

    function _getModules() internal view returns (address[] memory) {
        return ISafe(safe).getModules();
    }

    function _isModuleEnabled(address module) internal view returns (bool) {
        return ISafe(safe).isModuleEnabled(module);
    }
}

interface ISafe {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
    function getTransactionCount() external view returns (uint256);
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 nonce
    ) external view returns (bytes32);
    function isOwner(address owner) external view returns (bool);
    function getModules() external view returns (address[] memory);
    function isModuleEnabled(address module) external view returns (bool);
}
