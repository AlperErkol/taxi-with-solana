pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

contract Taxi {

    uint private MAXIMUM_PARTICIPANT = 9;
    
    struct Participant {
        address payable participantAddress;
        uint balance;
    }

    struct TaxiDriver {
        address payable driverAddress;
        uint salary;
        uint approvalState;
        uint disapprovalState;
        uint isApproved;
        uint balance;
        uint lastPaid;
    }

    struct CarProposal {
        uint32 carId;
        uint price;
        uint offerValidTime;
        uint approvalState;
    }
    
    // Participant - Address mapping 
    
    mapping (address => Participant) participants;
    
    // List of address of participant, maximum of 9.
    address[] participantsAddresses;

    // Initializing taxi driver
    TaxiDriver driver;
    TaxiDriver approvedDriver;

    // Total amount of balance
    uint contractBalance;
 
    // Fixed 10 ether for 6-month.
    uint fixedExpenses;

    // Last Maintanance time to check 6 months.
    uint lastMaintanence;

    // Fixed 100 ether to participate.
    uint participationFee;

    // Last time of the pay for the participations.
    uint participationSalaryTime;

    // Car ID
    uint32 carId;

    // Proposed Car
    CarProposal proposedCar;

    // Proposed Repurchase
    CarProposal proposedRepurchase;

    address private owner;

    address payable carDealer;


    // Modifiers Start
    modifier isCarDealer() {
        require(msg.sender == carDealer, "You must be a car dealer to call this function.");
        _;
    }

    modifier isTaxiDriver() {
        require(msg.sender == driver.driverAddress, "You must be a taxi driver to call this function.");
        _;
    }

    modifier isParticipant() {
        require(participants[msg.sender].participantAddress != address(0), "You must be a participant to call this function.");
        _;
    }


    // Modifiers End


    constructor(){

        // initialize some of state variables
        owner = msg.sender;
        contractBalance = 0;
        fixedExpenses = 10 ether;
        participationFee = 100 ether;
        lastMaintanence = block.timestamp;
        
        
    }

    function join() public payable {

        require(participantsAddresses.length >= MAXIMUM_PARTICIPANT, "Participant list is full!");
        // Check the participant have enough money or not.
        require(msg.value >= participationFee, "Payment failed!");
        participantsAddresses.push(msg.sender);
        contractBalance += msg.value;
    }


    function carProposeToBusiness(uint32 _carId, uint price, uint offerValidTime) public isCarDealer{
        // Initialize new instance of CarProposal
        // Set approval state to 0.
        proposedCar = CarProposal(_carId,price,offerValidTime,0);
    }

    function ApprovePurchaseCar() public isParticipant{
        // incremeny by one of approval state of proposed car.
        proposedCar.approvalState += 1;
        
        // if approval state is more than half of the participants, call purchase car function.
        if(proposedCar.approvalState > (participantsAddresses.length / 2)){
            PurchaseCar();
        }

    }

    function PurchaseCar() public{
        require(proposedCar.offerValidTime >= block.timestamp,"Offer Valid Time passed!");
        carDealer.transfer(proposedCar.price);
        contractBalance -= proposedCar.price;
    }

    function RepurchaseCarPropose(uint32 _carId, uint price, uint offerValidTime) public isCarDealer{
        // Set approval state to 0.
        proposedRepurchase = CarProposal(_carId,price,offerValidTime,0);
    }

    function ApproveSellProposal() public isParticipant {
        // incremeny by one of approval state of proposed repurchase car.
        proposedRepurchase.approvalState += 1;

        // if approval state is more than half of the participants, call repurchase car function.
        if(proposedRepurchase.approvalState > (participantsAddresses.length / 2)){
            RepurchaseCar();
        }

    }

    function RepurchaseCar() public isCarDealer{
        // check for exceeding offer valid time
        require(proposedRepurchase.offerValidTime >= block.timestamp,"Offer Valid Time passed!");
        // send the price to car dealer
        carDealer.transfer(proposedRepurchase.price);
        // decrement contract balance by car price
        contractBalance-=proposedRepurchase.price;
    }

    function ProposeDriver(address payable driverAddress, uint salary) public{
        // initialize new taxi driver to propose
        driver = TaxiDriver(driverAddress,salary,0,0,0,0,block.timestamp);
    }

    function ApproveDriver() public isParticipant {
        // incremeny by one of approval state of proposed driver.
        driver.approvalState += 1;

        // if approval state is more than half of the participants, call set driver.
        if(driver.approvalState > (participantsAddresses.length / 2)){
            SetDriver(driver.driverAddress,driver.salary);
        }
        
    }

    function SetDriver(address payable driverAddress, uint salary) public {
        // set driver as a new driver and delete proposed driver.
        approvedDriver = TaxiDriver(driverAddress,salary,0,0,0,0,block.timestamp);
        approvedDriver.isApproved = 1;
        delete driver;
        
    }

    function ProposeFireDriver() public isParticipant {
        // incremeny by one of disapproval state of proposed driver.
        driver.disapprovalState += 1;

        // if disapproval state is more than half of the participants, call fire driver.
        if(driver.disapprovalState > (participantsAddresses.length / 2)){
            FireDriver();
        }

    }

    function FireDriver() public {
        // delete driver and send his/her balance to his or her.
        driver.driverAddress.transfer(driver.balance);
        delete driver;
    }

    function LeaveJob() public isTaxiDriver {
        FireDriver();
    }

    function GetCharge() public payable {
        contractBalance+=msg.value;
    }

    function GetSalary() public payable isTaxiDriver {
        require(block.timestamp - driver.lastPaid >= 2629743,"Your monthly salary has been deposited.");
        driver.driverAddress.transfer(driver.salary);
        driver.driverAddress.transfer(driver.balance);
        driver.lastPaid = block.timestamp;
    }

    function CarExpenses() public payable isParticipant{
        require(block.timestamp - lastMaintanence >= 15778463,"Your 6-month car maintanance expenses has been deposited.");
        contractBalance -= fixedExpenses;
        carDealer.transfer(fixedExpenses);
        lastMaintanence = block.timestamp;
    }

    function PayDividend() public isParticipant{
        require(block.timestamp - participationSalaryTime >= 15778463,"Your 6-month c expenses has been deposited.");
        uint totalProfit = contractBalance - (driver.salary + fixedExpenses + (participationFee * participantsAddresses.length));    
        uint profitPerParticipant = totalProfit / participantsAddresses.length;
        for(uint i = 0; i < participantsAddresses.length; i++){
            participants[participantsAddresses[i]].balance += profitPerParticipant;
        }
        contractBalance = 0;
        participationSalaryTime = block.timestamp;
    }

    function GetDividend() public payable isParticipant{
        participants[msg.sender].participantAddress.transfer(participants[msg.sender].balance);
        participants[msg.sender].balance = 0;
    }
    
    fallback() external  {
        revert();
    }





}