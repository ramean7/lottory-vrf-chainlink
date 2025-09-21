// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import{Test} from "forge-std/Test.sol";
import{Raffle} from "../src/Raffle.sol"; 
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test{

    event RaffleEnter(address indexed player);

    address user2 = makeAddr("user2");
    address user = makeAddr("user");
    address user3 = makeAddr("user3");

    Raffle raffle;    
    VRFCoordinatorV2_5Mock vrfMock;
    bytes32 gasLane = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;
    uint256 enterFee = 0.01 ether;

    function setUp() public{
        
        vrfMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UINT_LINK);
        uint256 subId = vrfMock.createSubscription();
        vrfMock.fundSubscription(subId , 1 ether);

        raffle = new Raffle(subId,gasLane,30,enterFee,500000,address(vrfMock));
        vrfMock.addConsumer(subId , address(raffle));

    }

    function testEnterRaffle()public{
        vm.startPrank(user);
        vm.deal(user,1 ether);
        raffle.enterRaffle{value:enterFee}();
        address index = raffle.getPlayers(0);        
        assertEq(index , user);
        vm.stopPrank();
    }

    function testCantEnterWithOutFee() public{
        vm.startPrank(user);
        vm.deal(user,1 ether);
        vm.expectRevert();
        raffle.enterRaffle();
    } 

    function testFalseCheckUnkeep() public{
        vm.startPrank(user);
        vm.deal(user , 1 ether);
        raffle.enterRaffle{value:enterFee}();
        address index = raffle.getPlayers(0);        
        assertEq(index , user);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(false , upkeepNeeded);
        vm.stopPrank();
    }

    function testTrueCheckUnKeep() public{
        vm.startPrank(user);
        vm.deal(user , 1 ether);
        raffle.enterRaffle{value:enterFee}();
        address index = raffle.getPlayers(0);        
        assertEq(index , user);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 hours);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(true , upkeepNeeded);
        vm.stopPrank();
    }

    function testPerformUnkeep() public{
        vm.startPrank(user);
        vm.deal(user , 1 ether);
        raffle.enterRaffle{value:enterFee}();
        address index = raffle.getPlayers(0);        
        assertEq(index , user);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 hours);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(true , upkeepNeeded);

        raffle.performUpkeep("");
        vm.stopPrank();
    }

    function testCantPerformUnkeepRaffleState() public{
        vm.startPrank(user);
        vm.deal(user , 1 ether);
        raffle.enterRaffle{value:enterFee}();
        address index = raffle.getPlayers(0);        
        assertEq(index , user);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 hours);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(true , upkeepNeeded);

        raffle.performUpkeep("");
        vm.expectRevert();
        raffle.performUpkeep("");
        vm.stopPrank();
    }

    function testCantDoublePerformUnkeepRaffleState() public{
        vm.startPrank(user);
        vm.deal(user , 1 ether);
        raffle.enterRaffle{value:enterFee}();
        address index = raffle.getPlayers(0);        
        assertEq(index , user);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 hours);        

        raffle.performUpkeep("");       
        

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(false , upkeepNeeded);

        vm.expectRevert();
        raffle.performUpkeep(""); 
        vm.stopPrank();
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(user);
        vm.deal(user , 1 ether);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(user);
        raffle.enterRaffle{value: enterFee}();
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public {

        vm.prank(user);
        vm.deal(user, 1 ether);
        raffle.enterRaffle{value: enterFee}();
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        // Arrange
        // Act / Assert
        vm.expectRevert();
        // vm.mockCall could be used here...
        vrfMock.fulfillRandomWords(0, address(raffle));

        vm.expectRevert();
        vrfMock.fulfillRandomWords(1, address(raffle));
    }

    function testRequestId()public{
        vm.prank(user);
        vm.deal(user, 1 ether);
        raffle.enterRaffle{value: enterFee}();
        vm.warp(block.timestamp + 1 hours);
        vm.roll(block.number + 1);
        uint256 requestId = raffle.requestRandomWords();
        assertEq(requestId , raffle.getLastRequestId());
        assertEq(raffle.getRequestIds(0) , requestId);
        Raffle.RequestStatus memory status = raffle.getMapping(requestId);
        assertEq(status.exists , true);
        assertEq(status.fulfilled, false);
    }

    function testFulfillRandomWordsWorksAfterPerformUpkeep() public {
    vm.deal(user, 1 ether);
    vm.deal(address(raffle),100 ether);
    vm.prank(user);
    raffle.enterRaffle{value: enterFee}();

    vm.warp(block.timestamp + 1 hours);
    vm.roll(block.number + 1);

    // اول باید performUpkeep اجرا بشه
    raffle.performUpkeep("");

    // حالا requestId معتبر داریم، مثلاً اولینش 1 میشه
    vrfMock.fulfillRandomWords(1, address(raffle));

    // اینجا می‌تونی انتظار داشته باشی winner انتخاب شده باشه
    address recentWinner = raffle.getRecentWinner();
    assertEq(recentWinner, user);
}


    
}