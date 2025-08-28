// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";
import "forge-std/Vm.sol";
import {UniswapTrap, CollectOutput} from "../src/UniswapTrap.sol";

contract UniswapTrapTest is Test {
    uint256 forkId;
    UniswapTrap public trap;
    address public pool = 0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36; // ETH/USDT pool
    uint256 blockNumber = 23227083;

    function setUp() public {
        forkId = vm.createSelectFork(vm.rpcUrl("ethereum"), blockNumber);
        trap = new UniswapTrap();
        trap.setupTest(pool);
    }

    function test_fork_collectAndRespond() public {
        
        Vm.EthGetLogs[] memory poolLogs = vm.eth_getLogs(
            blockNumber,   // from
            blockNumber,   // to
            address(pool),
            new bytes32[](0)
        );
        
        console.log("Uniswap V3 pool logs in current block:", poolLogs.length);
        
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
        console.log("Swap events found:", collectOutput.swapEvents.length);
        console.log("Mint events found:", collectOutput.mintEvents.length);
        console.log("Burn events found:", collectOutput.burnEvents.length);
        console.log("Collect events found:", collectOutput.collectEvents.length);
        console.log("Flash events found:", collectOutput.flashEvents.length);
        console.log("Total events found:", collectOutput.swapEvents.length + collectOutput.mintEvents.length + collectOutput.burnEvents.length + collectOutput.collectEvents.length + collectOutput.flashEvents.length);
        
        bytes[] memory data = new bytes[](1);
        data[0] = result;

        // check if the trap should respond
        (bool shouldRespond, bytes memory response) = trap.shouldRespond(data);
        assertTrue(shouldRespond);
    }
}