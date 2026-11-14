//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Betting{
    struct Bet{
        address payable better;
        uint amount;
        uint team_no;
    }
    Bet [] public bets;
    uint public team1_amount;
    uint public team2_amount;
    uint public total_bets;
    uint public result;
    uint public min_bet_amount;
    address payable public owner;
    constructor(uint _min_bet_amount){
        owner=payable(msg.sender);
        min_bet_amount=_min_bet_amount;

    }
    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can call this function");
        _;
    }
    string public team1_name;
    string public team2_name;
    bool public teams_set=false;
    bool public betting_open=false;
    bool public match_ended=false;
    bool public prizes_distributed=false;
    function set_teams(string memory _team1_name,string memory _team2_name) public onlyOwner{
        require(betting_open==false,"Betting is already open");
        require(teams_set==false,"The teams are already set");
        team1_name=_team1_name;
        team2_name=_team2_name;
        teams_set=true;
    }
    function start_betting() public onlyOwner{
        require(teams_set==true,"Teams aren't set yet");
        require(betting_open==false,"Betting is already open");
        require(match_ended==false,"Match has already ended");
        betting_open=true;
    }
    function close_betting() public onlyOwner{
        require(betting_open==true,"Betting is already closed");
        betting_open=false;
    }
    function put_bet(uint _team_no) public payable{
        require(teams_set==true,"The teams aren't set");
        require(betting_open==true,"Betting is closed");
        require(_team_no==1 ||_team_no==2,"Please enter either 1 or 2");
        require(msg.value>=min_bet_amount,"Please bet greater than or equal to minimum betting amount");
        bets.push(Bet({better:payable(msg.sender),amount:msg.value,team_no:_team_no}));
        if(_team_no==1){
            team1_amount+=msg.value;
        }
        else{
            team2_amount+=msg.value;
        }
        total_bets++;
    }


    function declare_result(uint winner) public onlyOwner{
        require(match_ended==false, "Result already declared");
        require(betting_open==false,"Betting is still open");
        require(winner==1||winner==2,"Neither Team 1 nor Team 2 won");
        result=winner;
        match_ended=true;
    }
    function distribute_amount() public onlyOwner{
        require(match_ended==true,"The match hasn't ended");
        require(prizes_distributed==false,"The prizes have already been distributed");
        prizes_distributed = true;
        uint winning_bet;
        uint losing_bet;
        if(result==1){
            winning_bet=team1_amount;
            losing_bet=team2_amount;
        }
        else{
            winning_bet=team2_amount;
            losing_bet=team1_amount;
        }
        require(winning_bet>0,"Zero bets on winning team");
        for(uint i=0;i<bets.length;++i){
            if(bets[i].team_no==result){
                uint user_bet = bets[i].amount;
                uint reward=user_bet+((user_bet*losing_bet)/winning_bet);

                (bool success,) = bets[i].better.call{value:reward}("");
                require(success,"Transfer failed . Please try again");
            }
        }
    }}