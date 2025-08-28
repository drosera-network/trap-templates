// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC721Trap, CollectOutput} from "../src/ERC721Trap.sol";
import {Trap, EventFilter, EventFilterLib, EventLog} from "drosera-contracts/Trap.sol";
import "forge-std/Vm.sol";
import {IERC721} from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";

contract ERC721TrapTest is Test {
    uint256 forkId;
    ERC721Trap public trap;
    
    // BAYC contract address on mainnet
    address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address constant USER_TO_WATCH = 0xDccc435333cbaA10131c6EB1a27395CCF4E67C92;
    uint256 blockNumber = 22454887;

    function setUp() public {
        forkId = vm.createSelectFork(vm.rpcUrl("ethereum"), blockNumber);
        trap = new ERC721Trap();
        trap.setupTest(BAYC, USER_TO_WATCH);
    }

    function test_collect_with_real_mainnet_logs() public {
        
        Vm.EthGetLogs[] memory baycLogs = vm.eth_getLogs(
            blockNumber,   // from
            blockNumber,   // to
            address(BAYC),
            new bytes32[](0)
        );
        
        console.log("BAYC logs in current block:", baycLogs.length);
        
        // Convert Vm.EthGetLogs to EventLog format and set them in the trap
        EventLog[] memory eventLogs = new EventLog[](baycLogs.length);
        for (uint256 i = 0; i < baycLogs.length; i++) {
            eventLogs[i] = EventLog({
                emitter: baycLogs[i].emitter,
                topics: baycLogs[i].topics,
                data: baycLogs[i].data
            });
        }
        
        // Set the event logs in the trap
        trap.setEventLogs(eventLogs);
        
        
        console.log("Successfully set", baycLogs.length, "event logs in trap");

        bytes memory result = trap.collect();
        CollectOutput memory collectOutput = abi.decode(result, (CollectOutput));
        console.log("Transfer events found:", collectOutput.transferEvents.length);
        console.log("Approval events found:", collectOutput.approvalEvents.length);
        console.log("ApprovalForAll events found:", collectOutput.approvalForAllEvents.length);
        console.log("Total holding:", collectOutput.totalHolding);
        
        bytes[] memory data = new bytes[](1);
        data[0] = result;

        // check if the trap should respond
        (bool shouldRespond, bytes memory response) = trap.shouldRespond(data);
        assertTrue(shouldRespond);
    }

}

