// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.13;

import {OVMClient} from "@webisopen/ovm-contracts/src/OVMClient.sol";
import {
    Arch,
    ExecMode,
    GPUModel,
    Requirement,
    Specification
} from "@webisopen/ovm-contracts/src/libraries/DataTypes.sol";

event ResponseParsed(bytes32 requestId, bool success, string seqParsed);

contract SeqAlign is OVMClient {
    bool public constant REQ_DETERMINISTIC = true;

    mapping(bytes32 requestId => string _seqParsed) internal _responseData;

    /**
     * @dev Constructor function for the PI contract.
     * @param OVMGatewayAddress The address of the OVMGateway contract.
     * @param admin The address of the admin.
     */
    constructor(address OVMGatewayAddress, address admin) OVMClient(OVMGatewayAddress, admin) {
        // set specification
        Specification memory spec;
        spec.name = "ovm-cal-pi";
        spec.version = "1.0.0";
        spec.description = "Sequence Alignment";
        spec.repository = "https://github.com/webisopen/seq-aligner";
        spec.repoTag = "contract-v0.1.0";
        spec.license = "WTFPL";
        spec.requirement = Requirement({
            ram: "256mb",
            disk: "5mb",
            timeout: 600,
            cpu: 1,
            gpu: 0,
            gpuModel: GPUModel.T4
        });
        spec.apiABIs =
            '[{"request": {"type":"function","name":"sendRequest","inputs":[{"name":"numDigits","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"requestId","type":"bytes32","internalType":"bytes32"}],"stateMutability":"payable"},"getResponse":{"type":"function","name":"getResponse","inputs":[{"name":"requestId","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"}}]';
        spec.royalty = 5;
        spec.execMode = ExecMode.JIT;
        spec.arch = Arch.AMD64;

        _updateSpecification(spec);
    }

    /**
     * @dev Sends a request to align two sequences.
     * @param seq1 The first sequence to align(in url format).
     * @param seq2 The second sequence to align(in url format).
     * @return requestId The ID of the request returned by the OVMGateway contract.
     */
    function sendRequest(string calldata seq1, string calldata seq2) external payable returns (bytes32 requestId) {
        // encode the two sequences
        bytes memory data = abi.encode(seq1, seq2);
        requestId = _sendRequest(msg.sender, msg.value, REQ_DETERMINISTIC, data);
    }

    /**
     * @dev Sets the response data for a specific request. This function is called by the OVMGateway
     * contract.
     * @param requestId The ID of the request.
     * @param data The response data to be set.
     */
    function setResponse(bytes32 requestId, bytes calldata data)
        external
        override
        recordResponse(requestId)
        onlyOVMGateway
    {
        // parse and save the data fulfilled by the OVMGateway contract
        (bool success, string memory seqParsed) = _parseData(data);
        if (success) {
            _responseData[requestId] = seqParsed;
        }

        emit ResponseParsed(requestId, success, seqParsed);
    }

    /**
     * @dev Retrieves the response associated with the given request ID.
     * @param requestId The ID of the request.
     * @return The response data as a string in our pi calculation case.
     */
    function getResponse(bytes32 requestId) external view returns (string memory) {
        return _responseData[requestId];
    }

    /**
     * @dev Parses the given data and returns a boolean value and a string.
     * @param data The input data to be parsed.
     * @return A tuple containing a boolean value indicating the success of the task execution
     * and a string representing the parsed data.
     */
    function _parseData(bytes calldata data) internal pure returns (bool, string memory) {
        return abi.decode(data, (bool, string));
    }
}
