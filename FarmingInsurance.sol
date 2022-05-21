// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract FarmingInsurance{
    using BokkyPooBahsDateTimeLibrary for uint;
    address payable owner;

    constructor(){
        owner = payable(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner , "only owner can use this function");
        _;
    }

    modifier canSubscribe(uint _landArea){
        if(calcSubscribeFees(_landArea) != msg.value){
            revert("You dont send enough ether");
        }
        _;
    }



    // return end date as string in YYYY/MM/DD format
    function getEndDateString() private view returns (string memory) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(block.timestamp + 30 days);
        return concatenateDate(year,month,day);
    }

    // return current date as string in YYYY/MM/DD format
    function getTodayDateString() private view returns (string memory) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(block.timestamp);
        return concatenateDate(year,month,day);
    }

    // convert uint year / month / day to string
    function concatenateDate(uint a,uint b , uint c) private pure returns (string memory){
        return string(abi.encodePacked(Strings.toString(a),'/',Strings.toString(b) , '/' ,Strings.toString(c)));
    } 

    struct Subscription {
        string location;
        uint landArea;
        address payable userAddress;
    }


   mapping(string => Subscription[]) public subscribers;

    function subscribe(uint _landArea , string memory _location) public canSubscribe(_landArea) payable{
        bool sent = owner.send(calcSubscribeFees(_landArea));
        require(sent , "transaction failed");
        subscribers[getEndDateString()].push(Subscription(_location, _landArea , payable(msg.sender)));
    }

    function calcSubscribeFees(uint _landArea) public pure returns(uint256){
        return _landArea  * 5 * 10**14; // 1000 meters = 0.5 ETH
    }

    function calcInsuranceFees(uint _landArea) public pure returns(uint256){
        return _landArea  * 2  * 10**15; // 1000 meters = 2 ETH
    }

    function getEndDayEqToday() public view returns(Subscription[] memory) {
        return subscribers[getTodayDateString()];
    }

    function runEveryDayAndSendInsuranceValues(uint[] memory rainfallAverage) public onlyOwner payable{
        Subscription[] memory temp = getEndDayEqToday();
        if(rainfallAverage.length != temp.length){
            revert("the length of rainfall array and subscribers not equal");
        }

        for (uint i=0; i<rainfallAverage.length; i++) {
            if(rainfallAverage[i] < 30){
                bool sent =  temp[i].userAddress.send(calcInsuranceFees(temp[i].landArea));
                require(sent , "transaction failed");
            }
        }
    } 
}
