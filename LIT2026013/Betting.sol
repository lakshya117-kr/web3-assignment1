
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Betting {

    struct Bet {
        address payable better;
        uint amount;
        uint team_no;
    }

    Bet[] public bets;

    uint public team1_amount;
    uint public team2_amount;
    uint public total_bets;
    uint public result;

    address public owner;

    uint public min_bet_amount;

    string public team1_name;
    string public team2_name;

    bool public teams_set;
    bool public betting_open;
    bool public match_ended;
    bool public distributed;

    // Constructor
    constructor(uint _min_bet_amount) {
        owner = msg.sender;
        min_bet_amount = _min_bet_amount;

        betting_open = false;
        teams_set = false;
        match_ended = false;
        distributed = false;
    }

    // Owner-only modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Set team names
    function set_teams(
        string memory _team1_name,
        string memory _team2_name
    ) public onlyOwner {
        require(!teams_set, "Teams already configured");
        require(bytes(_team1_name).length > 0, "Invalid team 1 name");
        require(bytes(_team2_name).length > 0, "Invalid team 2 name");

        team1_name = _team1_name;
        team2_name = _team2_name;
        teams_set = true;
    }

    // Open betting
    function open_betting() public onlyOwner {
        require(teams_set, "Set teams first");
        require(!match_ended, "Match already ended");
        require(!betting_open, "Betting already open");

        betting_open = true;
    }

    // Close betting
    function close_betting() public onlyOwner {
        require(betting_open, "Betting is not open");

        betting_open = false;
    }

    // Place a bet
    function put_bet(uint team_no) public payable {
        require(teams_set, "Teams are not configured");
        require(betting_open, "Betting is closed");
        require(team_no == 1 || team_no == 2, "Invalid team number");
        require(msg.value >= min_bet_amount, "Bet amount too low");

        bets.push(Bet({
            better: payable(msg.sender),
            amount: msg.value,
            team_no: team_no
        }));

        if (team_no == 1) {
            team1_amount += msg.value;
        } else {
            team2_amount += msg.value;
        }

        total_bets++;
    }

    // Declare match result
    function declare_result(uint winner) public onlyOwner {
        require(!betting_open, "Close betting first");
        require(!match_ended, "Result already declared");
        require(winner == 1 || winner == 2, "Invalid winner");

        result = winner;
        match_ended = true;
    }

    // Distribute winning amount
    function distribute_amount() public {
        require(match_ended, "Match has not ended");
        require(!distributed, "Amount already distributed");

        uint winning_amount;
        uint losing_amount;

        if (result == 1) {
            winning_amount = team1_amount;
            losing_amount = team2_amount;
        } else {
            winning_amount = team2_amount;
            losing_amount = team1_amount;
        }

        require(winning_amount > 0, "No winning bets");

        // Prevent repeated distribution
        distributed = true;

        for (uint i = 0; i < bets.length; i++) {
            if (bets[i].team_no == result) {

                uint reward = bets[i].amount
                    + (bets[i].amount * losing_amount)
                    / winning_amount;

                (bool success, ) = bets[i].better.call{
                    value: reward
                }("");

                require(success, "ETH transfer failed");
            }
        }
    }
}
