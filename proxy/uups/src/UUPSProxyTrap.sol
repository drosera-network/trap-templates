// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Trap, EventFilter, EventFilterLib, EventLog} from "./Trap.sol";
import {StorageSlot} from "@openzeppelin/utils/StorageSlot.sol";

struct UpgradedEvent {
    address implementation;
}

struct AdminChangedEvent {
    address previousAdmin;
    address newAdmin;
}

struct BeaconUpgradedEvent {
    address beacon;
}

// Output struct for collected data
struct CollectOutput {
    UpgradedEvent[] upgradedEvents;
    AdminChangedEvent[] adminChangedEvents;
    BeaconUpgradedEvent[] beaconUpgradedEvents;
    uint256 totalUpgrades;
    uint256 totalAdminChanges;
    uint256 totalBeaconUpgrades;
}

contract UUPSProxyTrap is Trap {
    using EventFilterLib for EventFilter;

    address public immutable proxy = address(0x0000000000000000000000000000000000000000); // UUPS proxy contract

    function collect() external view override returns (bytes memory) {
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        (uint256 upgradedCount, uint256 adminChangedCount, uint256 beaconUpgradedCount) = _countEvents(logs, filters);

        UpgradedEvent[] memory upgradedEvents = new UpgradedEvent[](upgradedCount);
        AdminChangedEvent[] memory adminChangedEvents = new AdminChangedEvent[](adminChangedCount);
        BeaconUpgradedEvent[] memory beaconUpgradedEvents = new BeaconUpgradedEvent[](beaconUpgradedCount);

        (uint256 totalUpgrades, uint256 totalAdminChanges, uint256 totalBeaconUpgrades) =
            _parseEvents(logs, filters, upgradedEvents, adminChangedEvents, beaconUpgradedEvents);

        return abi.encode(
            CollectOutput({
                upgradedEvents: upgradedEvents,
                adminChangedEvents: adminChangedEvents,
                beaconUpgradedEvents: beaconUpgradedEvents,
                totalUpgrades: totalUpgrades,
                totalAdminChanges: totalAdminChanges,
                totalBeaconUpgrades: totalBeaconUpgrades
            })
        );
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));

        // Check for anomalies
        // e.g., frequent upgrades, suspicious admin changes, beacon upgrades
        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](3);

        filters[0] = EventFilter({contractAddress: proxy, signature: "Upgraded(address)"});
        filters[1] = EventFilter({contractAddress: proxy, signature: "AdminChanged(address,address)"});
        filters[2] = EventFilter({contractAddress: proxy, signature: "BeaconUpgraded(address)"});

        return filters;
    }

    function _countEvents(EventLog[] memory logs, EventFilter[] memory filters)
        internal
        pure
        returns (uint256 upgradedCount, uint256 adminChangedCount, uint256 beaconUpgradedCount)
    {
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                upgradedCount++;
            }
            if (filters[1].matches(log)) {
                adminChangedCount++;
            }
            if (filters[2].matches(log)) {
                beaconUpgradedCount++;
            }
        }
    }

    function _parseEvents(
        EventLog[] memory logs,
        EventFilter[] memory filters,
        UpgradedEvent[] memory upgradedEvents,
        AdminChangedEvent[] memory adminChangedEvents,
        BeaconUpgradedEvent[] memory beaconUpgradedEvents
    ) internal pure returns (uint256 totalUpgrades, uint256 totalAdminChanges, uint256 totalBeaconUpgrades) {
        uint256 upgradedIndex = 0;
        uint256 adminChangedIndex = 0;
        uint256 beaconUpgradedIndex = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                upgradedEvents[upgradedIndex] = _parseUpgradedEvent(log);
                totalUpgrades++;
                upgradedIndex++;
            }
            if (filters[1].matches(log)) {
                adminChangedEvents[adminChangedIndex] = _parseAdminChangedEvent(log);
                totalAdminChanges++;
                adminChangedIndex++;
            }
            if (filters[2].matches(log)) {
                beaconUpgradedEvents[beaconUpgradedIndex] = _parseBeaconUpgradedEvent(log);
                totalBeaconUpgrades++;
                beaconUpgradedIndex++;
            }
        }
    }

    function _parseUpgradedEvent(EventLog memory log) internal pure returns (UpgradedEvent memory upgradedEvent) {
        address implementation = address(uint160(uint256(log.topics[1])));

        upgradedEvent = UpgradedEvent({implementation: implementation});
    }

    function _parseAdminChangedEvent(EventLog memory log)
        internal
        pure
        returns (AdminChangedEvent memory adminChangedEvent)
    {
        (address previousAdmin, address newAdmin) = abi.decode(log.data, (address, address));

        adminChangedEvent = AdminChangedEvent({previousAdmin: previousAdmin, newAdmin: newAdmin});
    }

    function _parseBeaconUpgradedEvent(EventLog memory log)
        internal
        pure
        returns (BeaconUpgradedEvent memory beaconUpgradedEvent)
    {
        address beacon = address(uint160(uint256(log.topics[1])));

        beaconUpgradedEvent = BeaconUpgradedEvent({beacon: beacon});
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IUUPSProxy(proxy).proxiableUUID()).value;
    }
}

interface IUUPSProxy {
    function proxiableUUID() external view returns (bytes32);
}
