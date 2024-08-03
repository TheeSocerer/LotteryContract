// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.7.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


contract LottoF is VRFConsumerBaseV2Plus {

// 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 link fuji
    uint256 private s_subscriptionId; // Kept as uint256
    address private vrfCoordinator = 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE;
    bytes32 private s_keyHash = 0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887;
    uint16 private requestConfirmations = 3;
    uint32 private numWords = 9;
    uint32 private callbackGasLimit =  2500000;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    uint256 public lastRequestId;

  
    constructor(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
    }

    // close the draw and get a random number
    function rollDice() public onlyOwner returns (uint256 requestId) {
        /*
        Request Id Stores the ChainLink VRF request Id, this is fetched once we execute the function
        and from there we will obtain a random number that we can use to obtain the winning numbers.
        */
        

        /*
        Lets finally call ChainLink VRFv2 and obtain the winning numbers from the randomness generator.
        */
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0)
        });
        lastRequestId = requestId;
        
        
    }

    function get_6_Numbers() external view onlyOwner returns (uint256[6] memory) {
        uint256[] memory numbers = s_requests[lastRequestId].randomWords;
        require(numbers.length >= 6, "Insufficient random numbers");
        uint256[6] memory finalNumbers = [numbers[0] % 49, numbers[1] % 49, numbers[2] % 49, numbers[3] % 49, numbers[4] % 49, numbers[5] % 49];
        return finalNumbers;
    }

    /*
    Chainlink VRFv2 Specific functions required in the smart contract for full functionality.
    */

    function getRequestStatus() external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[lastRequestId].exists, "request not found");
        RequestStatus memory request = s_requests[lastRequestId];
        return (request.fulfilled, request.randomWords);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
    }


    function sortArrays(uint[6] memory numbers) internal pure returns (uint[6] memory) {
            bool swapped;
        for (uint i = 1; i < numbers.length; i++) {
            swapped = false;
            for (uint j = 0; j < numbers.length - i; j++) {
                uint next = numbers[j + 1];
                uint actual = numbers[j];
                if (next < actual) {
                    numbers[j] = next;
                    numbers[j + 1] = actual;
                    swapped = true;
                }
            }
            if (!swapped) {
                return numbers;
            }
        }
        return numbers;
    }
   
   function WinningNumbers(uint[6] memory array) external view onlyOwner returns (uint256[6] memory) {
    uint[6] memory cOrder;
    cOrder = sortArrays(array);
    //bytes32 encodeWin = keccak256(abi.encodePacked(cOrder));
    return cOrder;
   }

  
}
