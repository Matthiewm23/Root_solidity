// SPDX-License-Identifier: GNU GPL

pragma solidity ^0.8.7;
import "./Preferundum.sol";

contract Referundum is Preferundum {

    uint RetroactionTime = 10 days ; // Time where people can cancel a vote after the results
    
    struct Vote {
        uint id; // the response for the proposition with id
        string response;
        address adressparticipant;
        uint nbtoken;
        address payable  addressvote;

    }

    Vote[] public votes ; 

    mapping (address => uint[]) public votebyowner;
    uint[] countcancel ;

    function answerquestion (string calldata _response, uint  _id, uint _nbtoken ) public payable  {
        require(stopgovernance(_id)==false);
        require(msg.value == _nbtoken);
        if(block.timestamp - governances[_id].date < DecisionTime && block.timestamp - governances[_id].date>ProposalTime){
            for(uint i =0; i<votebyowner[msg.sender].length ; i++) { // verify the user address has 
                require (votebyowner[msg.sender][i] != _id);      //only voted once
            }
        }
        votes.push(Vote(_id, _response , msg.sender, _nbtoken,payable(msg.sender))); 
        votebyowner[msg.sender].push(_id); // We put that the participant has answered to the question

    }

    function getbacktokenn (uint _id)   public payable onlyOwner{
        for (uint i=0 ; i<votes.length ; i++){
            if(votes[i].id==_id){
                votes[i].addressvote.transfer(votes[i].nbtoken);
            }
        }
    }    

    function results (uint  _id) public  returns (uint[] memory) {
        require (block.timestamp - governances[_id].date >DecisionTime);
        require(stopgovernance(_id)==false);
        uint[] memory count ; // the first is count the number of tokens for accept the proposal Second is rejected.

        for (uint i=0 ; i<votes.length ; i++){
            if(votes[i].id == _id){
                if(keccak256(abi.encodePacked(votes[i].response))==keccak256(abi.encodePacked("aie"))) {
                    count[1]=count[1]+votes[i].nbtoken;
                }else{
                    count[2]=count[2]+votes[i].nbtoken;
                }
            }
        }      

        return count; 
    }    

    function canceldecision  (uint  _id, uint _nbtoken ) public {
        require (block.timestamp - governances[_id].date <RetroactionTime+DecisionTime);
        require(stopgovernance(_id)!=false);
        countcancel[_id] = countcancel[_id] + _nbtoken ;
    }

    function acceptbalance(uint _sum) public returns(bool){
        uint balancecontract ; 
        for (uint i=0 ; i<responses.length ; i++){
            balancecontract = balancecontract + responses[i].nbtoken + votes[i].nbtoken ;
        }
        return (balancecontract == address(this).balance - _sum);
    }

    function finaldecision (uint _id) public payable returns(string memory){
        if(results(_id)[1]>countcancel[_id]) {
            if(governances[_id].tresorery==1){
                uint sum ;
                for(uint i=0;i<governances[_id].subject.length;i++){
                         sum=sum+propositionchosen(_id).tresoreryaccount[i];
                     }
                if(acceptbalance(sum)){
                    governances[_id].ownerr.transfer(sum);
                }
            }
            return "Proposition of governance is accepted";
        } else {
            return "Proposition of governance is rejected";
        }
    }


}