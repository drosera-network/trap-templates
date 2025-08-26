// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EventLog, EventFilter} from "../src/Trap.sol";
import "forge-std/Vm.sol";
import {AaveTrap, CollectOutput} from "../src/AaveTrap.sol";

contract AaveTrapTest is Test {
    uint256 forkId;
    AaveTrap public trap;
    address public lendingPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; // Aave Lending Pool
    uint256 blockNumber = 23227336;

    function setUp() public {
        forkId = vm.createSelectFork(vm.rpcUrl("ethereum"), blockNumber);
        trap = new AaveTrap();
        trap.setupTest(lendingPool);
    }

    function test_fork_collectAndRespond() public {
        
        Vm.EthGetLogs[] memory poolLogs = vm.eth_getLogs(
            blockNumber,   // from
            blockNumber,   // to
            address(lendingPool),
            new bytes32[](0)
        );
        
        console.log("Aave Lending Pool logs in current block:", poolLogs.length);
        
        // Convert Vm.EthGetLogs to EventLog format and set them in the trap
        EventLog[] memory eventLogs = new EventLog[](poolLogs.length);
        for (uint256 i = 0; i < poolLogs.length; i++) {
            eventLogs[i] = EventLog({
                emitter: poolLogs[i].emitter,
                topics: poolLogs[i].topics,
                data: poolLogs[i].data
            });
        }
        
        // Set the event logs in the trap
        trap.setEventLogs(eventLogs);
        
        
        console.log("Successfully set", poolLogs.length, "event logs in trap");

        bytes memory result = trap.collect();
        CollectOutput memory collectOutput = abi.decode(result, (CollectOutput));
        
        // Log all event counts
        console.log("Supply events found:", collectOutput.supplyEvents.length);
        console.log("Borrow events found:", collectOutput.borrowEvents.length);
        console.log("Repay events found:", collectOutput.repayEvents.length);
        console.log("Liquidation events found:", collectOutput.liquidationEvents.length);
        console.log("Flash loan events found:", collectOutput.flashLoanEvents.length);
        console.log("Reserve update events found:", collectOutput.reserveUpdateEvents.length);
        console.log("Collateral events found:", collectOutput.collateralEvents.length);
        console.log("Swap events found:", collectOutput.swapEvents.length);
        
        
        bytes[] memory data = new bytes[](1);
        data[0] = result;

        // check if the trap should respond
        (bool shouldRespond, bytes memory response) = trap.shouldRespond(data);
        assertTrue(shouldRespond);
    }
}