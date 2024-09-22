// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Tahzbi Mahmud Rifat
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus{
    /* Errors */
    error Raffle__SendMoreToEnterRaffle(); // it is good to give the error name and use two __ befoe the error.
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /** Type Declarations: its a type variable */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /** State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    //storage variable 
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState; // start as open

    //Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint256 subscriptionId, 
        uint32 callbackGasLimit)
        VRFConsumerBaseV2Plus(vrfCoordinator) { // Here the first constructor will take input vrfCoordinator and pass it to second constructor as input which is the inherited from other contract.
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN; // Here RaffleState.OPEN will give value 0, It is same as RaffleState(0);
        // s_vrfCoordinator.requestRandomWords()
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        // 1. Makes migration easier
        // 2. Makes front end "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    //1. Get a random number 
    // 2. Use random number to pick a play 

    // When should the winner be picked?
    /**
     * @dev This is the function that the Chainlink nodes will call to see
     * If the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The  time interval has passed between raffle runs
     * 2. The lottery is open 
     * 3. The contract has ETH (has players)
     * 4. Implicityly, your subscript has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */

    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Important Note: If we use only bool in the argument then we have to return a true or false value and if we use upkeepNeeded then we doesn't have to return anything, we can simply set the upkeepNeeded value as true or false.
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);

        //special syntax
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        return (upkeepNeeded, "");
    }
    // 3. ** Be automatically called **
    function performUpkeep(bytes calldata /*performData */ ) external {
        // check to see if enough time has passed using block.timestamp

        // 1000 - 900 = 100, 50
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;

        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get RNG

        // Will revert if subscription is not set and funded.

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest(
            {
                keyHash: i_keyHash, // kkey hash for gass lane
                subId: i_subscriptionId, // how we are goign to fund
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS, // how many numbers we want
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            }
        );

        s_vrfCoordinator.requestRandomWords(request);
        // uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // CEI: check, Effects, Interactions Pattern
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        // The pattern is: Checks, Effects and Interations
        // Checks
        // requires(conditionals)

        // s_player = 10
        // range = 12
        // 12 % 10 = 2 <-
        // 32423423423434234324234234 % 10 = 9

        // Effect (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        // Patterns helps to reentrance check and use events before Interations and it is 

        // Interattions (External Contract Interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        } 
        emit WinnerPicked(s_recentWinner);

    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}