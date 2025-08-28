// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Trap, CollectOutput} from "../src/ERC20Trap.sol";
import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";
import "forge-std/Vm.sol";
import "forge-std/StdJson.sol";
import {AllLogsHelper} from "./utils/Logs.sol";
import {IERC20} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20TrapTest is AllLogsHelper {
    uint256 forkId;
    ERC20Trap public trap;
    
    // USDC contract address on mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USER_TO_WATCH = 0xD525FF06f7805E8dd26964F5970eDB5b2c97D939;

    function setUp() public {
        forkId = vm.createSelectFork(vm.rpcUrl("ethereum"));

        trap = new ERC20Trap();
        trap.setupTest(USDC, USER_TO_WATCH);
    }

    function test_collect_with_real_mainnet_logs() public {


        // getAllLogs(19000000, 19000000, new bytes32[](0)); // test this later
        
        // capture one block of logs
        Vm.EthGetLogs[] memory usdcLogs = vm.eth_getLogs(
            19000000,      // from
            19000000,      // to
            address(USDC),
            new bytes32[](0)
        );
        
        // Convert Vm.EthGetLogs to EventLog format and set them in the trap
        EventLog[] memory eventLogs = new EventLog[](usdcLogs.length);
        for (uint256 i = 0; i < usdcLogs.length; i++) {
            eventLogs[i] = EventLog({
                emitter: usdcLogs[i].emitter,
                topics: usdcLogs[i].topics,
                data: usdcLogs[i].data
            });
        }
        
        // simulate the operator setting the event logs
        trap.setEventLogs(eventLogs);
        
        // collect the data
        bytes memory result = trap.collect();
        CollectOutput memory collectOutput = abi.decode(result, (CollectOutput));
        console.log("Transfer events found:", collectOutput.transferEvents.length);
        console.log("Approval events found:", collectOutput.approvalEvents.length);
        console.log("USDC total supply:", collectOutput.totalSupply);

        bytes[] memory data = new bytes[](1);
        data[0] = result;

        // check if the trap should respond
        (bool shouldRespond, bytes memory response) = trap.shouldRespond(data);
        assertTrue(shouldRespond);
        
    }
}