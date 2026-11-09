//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Betting{
    struct Bet{
        address payable better;
        uint amount;
        uint team_no;
    }

    Bet[] public bets;
    // 0. (0x1093, 1eth, 1)
    // 1. (0x3842, 2eth, 2)

    uint public team1_amount=0;
    uint public team2_amount=0;
    uint public total_bets=0;
    uint public result;

    address public owner;
    uint public min_bet_amount;

    constructor(uint _min_bet_amount){
        owner = msg.sender;
        min_bet_amount = _min_bet_amount;
    }

    modifier onlyOwner{
      require(msg.sender==owner);
      _;
    }

    string public team1_name;
    string public team2_name;
    bool public teams_set=false;
    bool public betting_open=false;
    bool public match_ended=false;

    function set_team_names(string memory _team1, string memory _team2) public onlyOwner{
        require(teams_set==false, "team names are already set");
        team1_name = _team1;
        team2_name = _team2;
        teams_set = true;
        betting_open= true;
    }

    function put_bet(uint team_no) public payable{
        require(teams_set==true, "Teams are not configured");
        require(betting_open==true, "Betting is not open");
        require(team_no==1||team_no==2,"Enter valid Team number");
        require(msg.value>=min_bet_amount,"You are not meeting the bet threshhold.");
        bets.push(Bet(payable(msg.sender),msg.value,team_no));
        if(team_no==1){
          team1_amount+=msg.value;
        }
        else{
          team2_amount+=msg.value;
        }
        total_bets++;
    }

    function close_betting() public onlyOwner{
        require(betting_open==true, "Betting already closed!");
        betting_open = false;
    }

    function declare_result(uint winner) public onlyOwner{
      require(betting_open==false, "Betting is not closed yet.");
      require(winner==1||winner==2,"Enter valid Team number");
      require(teams_set==true,"The teams are not configured yet");
      result = winner;
      match_ended = true;
    }

    function distribute_amount() public onlyOwner payable{
    require(match_ended==true,"The match result has not been declared yet.");
    for(uint i=0;i<total_bets;i++){
      uint payoff = 0;
      if(bets[i].team_no==result){
        if(bets[i].team_no==1){
          payoff = bets[i].amount + (team2_amount*bets[i].amount)/team1_amount;
        }
        else{
          payoff = bets[i].amount + (team1_amount*bets[i].amount)/team2_amount;
        }
        (bool sol, ) = (bets[i].better).call{value:payoff}("");
        require(sol==true, "The payment was not successful");
      }
    }
    }
  }