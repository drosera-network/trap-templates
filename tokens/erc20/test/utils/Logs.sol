// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

abstract contract AllLogsHelper is Test {

    function getAllLogs(
        uint256 fromBlock,
        uint256 toBlock,
        bytes32[] memory topics
    ) internal returns (VmSafe.EthGetLogs[] memory) {
        string memory params = _buildParams(fromBlock, toBlock, topics);
        console.log("params");
        console.log(params);

        bytes memory raw = vm.rpc("eth_getLogs", params);

        return abi.decode(raw, (VmSafe.EthGetLogs[]));
    }

    function _buildParams(
        uint256 fromBlock,
        uint256 toBlock,
        bytes32[] memory topics
    ) private pure returns (string memory) {
        string memory p = string.concat(
            '[{"fromBlock":"', _hexQty(fromBlock),
            '","toBlock":"',   _hexQty(toBlock),   '"'
        );
        if (topics.length > 0) {
            p = string.concat(p, ',"topics":[', _topicsArray(topics), "]");
        }
        return string.concat(p, "}]");
    }

    function _topicsArray(bytes32[] memory t) private pure returns (string memory) {
        bytes memory out;
        for (uint256 i; i < t.length; ++i) {
            out = abi.encodePacked(out, '"', _hex32(t[i]), '"', i + 1 == t.length ? "" : ",");
        }
        return string(out);
    }

    function _hexQty(uint256 v) private pure returns (string memory) {
        if (v == 0) return "0x0";
        bytes16 HEX = 0x30313233343536373839616263646566;
        bytes memory buf = new bytes(64);
        uint256 i = 64;
        while (v != 0) { uint256 n = v & 0xF; buf[--i] = bytes1(HEX[n]); v >>= 4; }
        return string(abi.encodePacked("0x", _slice(buf, i, 64 - i)));
    }
    function _hex32(bytes32 b) private pure returns (string memory) {
        bytes16 HEX = 0x30313233343536373839616263646566;
        bytes memory out = new bytes(64);
        for (uint256 i; i < 32; ++i) { uint8 x = uint8(b[i]); out[2*i] = HEX[x>>4]; out[2*i+1] = HEX[x&0xF]; }
        return string(abi.encodePacked("0x", out));
    }
    function _slice(bytes memory data, uint256 start, uint256 len) private pure returns (bytes memory) {
        bytes memory out = new bytes(len);
        for (uint256 i; i < len; ++i) out[i] = data[start + i];
        return out;
    }
}