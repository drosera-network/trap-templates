// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

struct TransferEvent {
    address from;
    address to;
    uint256 amount;
}

struct ApprovalEvent {
    address owner;
    address spender;
    uint256 amount;
}

// Create a struct with any data you would like to use in the shouldRespond function
struct CollectOutput {
    TransferEvent[] transferEvents;
    ApprovalEvent[] approvalEvents;
    uint256 totalSupply;
    address userToWatch;
}


contract ERC20Trap is Trap {
    using EventFilterLib for EventFilter;

    address public token; // This will be set as the token your are monitoring
    address public userToWatch; // An address to watch for suspicious activity
    
    function collect() external view override returns (bytes memory) {
        uint256 totalSupply = _getTotalSupply();
        // Get the captured events for the block
        EventLog[] memory logs = getEventLogs();
        EventFilter[] memory filters = eventLogFilters();

        uint256 transferCount = 0;
        uint256 approvalCount = 0;
        
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                transferCount++;
            }
            if (filters[1].matches(log)) {
                approvalCount++;
            }
        }

        TransferEvent[] memory transferEvents = new TransferEvent[](transferCount);
        ApprovalEvent[] memory approvalEvents = new ApprovalEvent[](approvalCount);

        uint256 transferIndex = 0;
        uint256 approvalIndex = 0;
        
        for (uint256 i = 0; i < logs.length; i++) {
            EventLog memory log = logs[i];
            if (filters[0].matches(log)) {
                address from = address(uint160(uint256(log.topics[1])));
                address to = address(uint160(uint256(log.topics[2])));
                uint256 amount = abi.decode(log.data, (uint256));
                TransferEvent memory transferEvent = TransferEvent({
                    from: from,
                    to: to,
                    amount: amount
                });
                transferEvents[transferIndex] = transferEvent;
                transferIndex++;
            }
            if (filters[1].matches(log)) {
                address owner = address(uint160(uint256(log.topics[1])));
                address spender = address(uint160(uint256(log.topics[2])));
                uint256 amount = abi.decode(log.data, (uint256));
                ApprovalEvent memory approvalEvent = ApprovalEvent({
                    owner: owner,
                    spender: spender,
                    amount: amount
                });
                approvalEvents[approvalIndex] = approvalEvent;
                approvalIndex++;
            }
        }
        
        return abi.encode(CollectOutput({
            transferEvents: transferEvents,
            approvalEvents: approvalEvents,
            totalSupply: totalSupply,
            userToWatch: userToWatch
        }));
    }

    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        CollectOutput memory currOutput = abi.decode(data[0], (CollectOutput));
        // loop through the data you have collected and check for anomolies

        //Example: Watch for suspicious approval events
        if (currOutput.approvalEvents.length > 0) {
            for (uint256 i = 0; i < currOutput.approvalEvents.length; i++) {
                if (currOutput.approvalEvents[i].owner == currOutput.userToWatch) {
                    if (currOutput.approvalEvents[i].amount > 100000000) {
                        return (true, "");
                    }
                }
            }
        }
        return (false, "");
    }

    function eventLogFilters() public view override returns (EventFilter[] memory) {
        EventFilter[] memory filters = new EventFilter[](2);
        
        filters[0] = EventFilter({
            contractAddress: token,
            signature: "Transfer(address,address,uint256)"
        });
        
        filters[1] = EventFilter({
            contractAddress: token,
            signature: "Approval(address,address,uint256)"
        });
    
        
        return filters;
    }

    function _getTotalSupply() internal view returns (uint256) {
        return IERC20(token).totalSupply();
    }

    function _getBalance(address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    function _getAllowance(address owner, address spender) internal view returns (uint256) {
        return IERC20(token).allowance(owner, spender);
    }

    function _getName() internal view returns (string memory) {
        return IERC20Metadata(token).name();
    }

    function _getSymbol() internal view returns (string memory) {
        return IERC20Metadata(token).symbol();
    }

    function _getDecimals() internal view returns (uint8) {
        return IERC20Metadata(token).decimals();
    }


    // Used for testing
    function setupTest(address _token, address _userToWatch) external {
        token = _token;
        userToWatch = _userToWatch;
    }

}
