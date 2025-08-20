// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Trap, EventFilter, EventFilterLib, EventLog} from "./Trap.sol";
import {IERC721, IERC721Metadata} from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";

struct TransferEvent {
    address from;
    address to;
    uint256 tokenId;
}

struct ApprovalEvent {
    address owner;
    address approved;
    uint256 tokenId;
}

struct ApprovalForAllEvent {
    address owner;
    address operator;
    bool approved;
}

// Create a struct with any data you would like to use in the shouldRespond function
struct CollectOutput {
    TransferEvent[] transferEvents;
    ApprovalEvent[] approvalEvents;
    ApprovalForAllEvent[] approvalForAllEvents;
    uint256 totalHolding;
}

contract ERC721Trap is Trap {
    using EventFilterLib for EventFilter;
    address public immutable token = address(0x0000000000000000000000000000000000000000); // This will be set as the token you are monitoring
    address public immutable user = address(0x0000000000000000000000000000000000000000); // This will be set as a user address you're following
    
    function collect() external view override returns (bytes memory) {
        uint256 totalHolding = _getBalance(user);
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        uint256 transferCount = 0;
        uint256 approvalCount = 0;
        uint256 approvalForAllCount = 0;
        
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                transferCount++;
            }
            if (filters[1].matches(log)) {
                approvalCount++;
            }
            if (filters[2].matches(log)) {
                approvalForAllCount++;
            }
        }

        TransferEvent[] memory transferEvents = new TransferEvent[](transferCount);
        ApprovalEvent[] memory approvalEvents = new ApprovalEvent[](approvalCount);
        ApprovalForAllEvent[] memory approvalForAllEvents = new ApprovalForAllEvent[](approvalForAllCount);

        uint256 transferIndex = 0;
        uint256 approvalIndex = 0;
        uint256 approvalForAllIndex = 0;
        
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                address from = address(uint160(uint256(log.topics[1])));
                address to = address(uint160(uint256(log.topics[2])));
                uint256 tokenId = uint256(log.topics[3]);
                TransferEvent memory transferEvent = TransferEvent({
                    from: from,
                    to: to,
                    tokenId: tokenId
                });
                transferEvents[transferIndex] = transferEvent;
                transferIndex++;
            }
            if (filters[1].matches(log)) {
                address owner = address(uint160(uint256(log.topics[1])));
                address approved = address(uint160(uint256(log.topics[2])));
                uint256 tokenId = uint256(log.topics[3]);
                ApprovalEvent memory approvalEvent = ApprovalEvent({
                    owner: owner,
                    approved: approved,
                    tokenId: tokenId
                });
                approvalEvents[approvalIndex] = approvalEvent;
                approvalIndex++;
            }
            if (filters[2].matches(log)) {
                address owner = address(uint160(uint256(log.topics[1])));
                address operator = address(uint160(uint256(log.topics[2])));
                bool approved = abi.decode(log.data, (bool));
                ApprovalForAllEvent memory approvalForAllEvent = ApprovalForAllEvent({
                    owner: owner,
                    operator: operator,
                    approved: approved
                });
                approvalForAllEvents[approvalForAllIndex] = approvalForAllEvent;
                approvalForAllIndex++;
            }
        }
        
        return abi.encode(CollectOutput({
            transferEvents: transferEvents,
            approvalEvents: approvalEvents,
            approvalForAllEvents: approvalForAllEvents,
            totalHolding: totalHolding
        }));
    }

    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));
        // loop through the data you have collected and check for anomalies
        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](3);
        
        filters[0] = EventFilter({
            contractAddress: token,
            signature: "Transfer(address,address,uint256)"
        });
        
        filters[1] = EventFilter({
            contractAddress: token,
            signature: "Approval(address,address,uint256)"
        });

        filters[2] = EventFilter({
            contractAddress: token,
            signature: "ApprovalForAll(address,address,bool)"
        });
        
        return filters;
    }


    function _getBalance(address account) internal view returns (uint256) {
        return IERC721(token).balanceOf(account);
    }

    function _getOwnerOf(uint256 tokenId) internal view returns (address) {
        return IERC721(token).ownerOf(tokenId);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        return IERC721(token).getApproved(tokenId);
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return IERC721(token).isApprovedForAll(owner, operator);
    }

    function _getName() internal view returns (string memory) {
        return IERC721Metadata(token).name();
    }

    function _getSymbol() internal view returns (string memory) {
        return IERC721Metadata(token).symbol();
    }

    function _getTokenURI(uint256 tokenId) internal view returns (string memory) {
        return IERC721Metadata(token).tokenURI(tokenId);
    }
}
