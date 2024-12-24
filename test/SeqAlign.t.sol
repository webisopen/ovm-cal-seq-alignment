pragma solidity 0.8.24;

import {SeqAlign, ResponseParsed} from "../src/SeqAlign.sol";
import {Test} from "forge-std/Test.sol";

contract SeqAlignTest is Test {
    address public constant alice = address(0x1111);
    address public constant mockTask = address(0x1234abcd);
    SeqAlign public seqAlign;

    function setUp() public {
        seqAlign = new SeqAlign(mockTask, alice);
    }

    function testSetResponse() public {
        bytes memory mockData = abi.encode(true, "3.14159");
        vm.prank(mockTask);
        vm.expectEmit();
        emit ResponseParsed("0x1234", true, "3.14159");
        seqAlign.setResponse("0x1234", mockData);

        string memory strPI = seqAlign.getResponse("0x1234");
        vm.assertEq(strPI, "3.14159");
    }
}
