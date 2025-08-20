// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


abstract contract Trap {
    EventLog[] private eventLogs;

    /// @notice Collects data from the trap.
    /// @return The collected data as a bytes array.
    /// @dev This function is intended to be overridden by derived contracts to implement specific data collection logic.
    function collect() external view virtual returns (bytes memory);

    /// @notice Determines if an on-chain response should be made based on the provided data.
    /// @param data The data to evaluate for a response.
    /// @return A tuple containing a boolean indicating whether to respond and the response data as bytes.
    /// @dev This function is intended to be overridden by derived contracts to implement specific response logic
    function shouldRespond(
        bytes[] calldata data
    ) external pure virtual returns (bool, bytes memory);


    /// @notice Returns the event filters for the trap.
    /// @return An array of EventFilter objects.
    /// @dev This function is intended to be overridden by derived contracts to provide specific event filters
    /// that the trap should listen to. The default implementation returns an empty array.
    /// @dev The filters can be used to match against event logs emitted by other contracts.
    function eventLogFilters() public view virtual returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](0);
        return filters;
    }

    /// @notice Returns the version of the Trap.
    /// @return The version as a string.
    function version() public pure returns (string memory) {
        return "2.0";
    }

    /// @notice Sets the event logs in the trap.
    /// @param logs An array of EventLog objects to set.
    /// @dev This function should not be called. This function is designated to be used by the off-chain operator node.
    function setEventLogs(EventLog[] calldata logs) public {
       EventLog[] storage storageArray = eventLogs;

        // Set new logs
        for (uint256 i = 0; i < logs.length; i++) {
            storageArray.push(EventLog({
                emitter: logs[i].emitter,
                topics: logs[i].topics,
                data: logs[i].data
            }));
        }
    }

    /// @notice Retrieves the event logs stored in the trap.
    /// @return An array of EventLog objects containing the stored event logs.
    /// @dev This function returns a copy of the event logs stored in the trap. It does not modify the state of the contract.
    /// The logs can be used to analyze events emitted by other contracts that match the filters defined in `eventLogFilters`.
    /// @dev It is intended to be called in the `collect` function to gather event logs for further processing.
    function getEventLogs() public view returns (EventLog[] memory) {
        EventLog[] storage storageArray = eventLogs;
        EventLog[] memory logs = new EventLog[](storageArray.length);

        for (uint256 i = 0; i < storageArray.length; i++) {
            logs[i] = EventLog({
                emitter: storageArray[i].emitter,
                topics: storageArray[i].topics,
                data: storageArray[i].data
            });
        }
        return logs;
    }
}

struct EventLog {
    // The topics of the log, including the signature, if any.
    bytes32[] topics;
    // The raw data of the log.
    bytes data;
    // The address of the log's emitter.
    address emitter;
}

struct EventFilter {
    // The address of the contract to filter logs from.
    address contractAddress;
    // The topics to filter logs by.
    string signature;
}

/// @title Events Library
/// @notice A library for handling event logs and filters in smart contracts.
/// @dev This library provides functionality to create event filters, check if logs match filters, and compute topics for events.
library EventFilterLib {

    /// @notice Creates a topic0 from the given EventFilter.
    /// @param filter The EventFilter to create the topic0 from.
    /// @return The computed topic0 as a bytes32 value.
    /// @dev This function computes the first topic of the event filter by hashing the signature.
    function topic0(EventFilter memory filter) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(filter.signature));
    }

    /// @notice Checks if a log matches the given filter.
    /// @param filter The EventFilter to match against.
    /// @param log The EventLog to check.
    /// @return True if the log matches the filter's contract address and topic0, false otherwise.
    /// @dev This function checks if the log's emitter matches the filter's contract address and if the first topic of the log matches the filter's hash signature.
    function matches(
        EventFilter memory filter,
        EventLog memory log
    ) internal pure returns (bool) {
        // Check if the log's emitter matches the filter's contract address
        if (log.emitter != filter.contractAddress) {
            return false;
        }

        // Check if the first topic of the log matches the filter's topic0
        if (log.topics.length == 0 || log.topics[0] != topic0(filter)) {
            return false;
        }

        return true;
    }

    /// @notice Checks if a log matches the given filter's signature and has a zero contract address.
    /// @param filter The EventFilter to match against.
    /// @param log The EventLog to check.
    /// @return True if the log matches the filter's signature and has a zero contract address, false otherwise.
    function matches_signature(
        EventFilter memory filter,
        EventLog memory log
    ) internal pure returns (bool) {
        // Check if the signature matches and the contract address is zero
        return topic0(filter) == log.topics[0] && 
               filter.contractAddress == address(0);
    }
}