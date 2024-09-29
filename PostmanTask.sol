// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GuessingGame{
    address public owner;
    uint16 private toBeGuessed; //chosen by owner only
    bool roundActive;
    uint roundEndTime;
    uint prizePool;
    uint changeGuessFee = 0.01 ether; //implementing the changeGuess and withdraw feature

    //need to store user id and bet amount and their bets in a mapping
    mapping(address => uint[2]) public bets; 
    //where the bets[0] stores the guessed number and bets[1] is the bet amount.
    address[] public players; //to see who all are playing
    
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){ //modifier which will not allow other players to see the number or edit duration etc etc.
        require(msg.sender == owner, "You are not the Owner!");
        _;
    }

    modifier isActive(){ //modifier to check if a round is active at the time of placing bets
        require(roundActive==true && block.timestamp < roundEndTime, "Round is Inactive right now!");
        _;
    }

    function startRound(uint16 _number, uint _length) public onlyOwner(){
        require(roundActive == false, "A round is aldready in play, cant start another one"); //checks
        require(_number >= 1 && _number <= 20, "The number has to be between 1 and 20"); //checks if number is between 1 and 20

        toBeGuessed = _number;
        roundEndTime = _length + block.timestamp; //current time + the duration provided by the owner
        roundActive = true;
        prizePool = 0;

        delete players; //clearing the array from before

    }

    function placeBet(uint _guess) public payable isActive{ //this function needs to accept ether so payable.
        
        require(msg.sender != owner, "Try as a non owner next time :)");
        require(bets[msg.sender][0] == 0, "You can only place 1 bet!"); //because guess cannot be 0 so we check using that
        require(msg.value > 0, "You have to bet some amount!"); //if they try to bet 0
        require(_guess >=1 && _guess <= 20, "Guess needs to be between 1 and 20");

        bets[msg.sender][0] = _guess;
        bets[msg.sender][1] = msg.value; //storing the values in the mapping
        prizePool += msg.value;

        players.push(msg.sender); //adding them to the players array

    }

    function withdrawBet() public isActive{
        require(bets[msg.sender][0] != 0, "No bet to withdraw");
        payable(msg.sender).transfer(bets[msg.sender][1]);

        bets[msg.sender][0] = 0;
        bets[msg.sender][1] = 0; //resetting their number and bet amt

    }

    function changeGuess(uint _newGuess) public payable isActive {
        require(bets[msg.sender][0] != 0, "Can't change if you haven't placed");
        require(msg.value >= changeGuessFee, "Too poor to change your bet");
        require(_newGuess >= 1 && _newGuess <= 20, "Guess needs to be between 1 and 20");

        uint previousBet = bets[msg.sender][1];
        payable(msg.sender).transfer(previousBet); //transferring back the previous bet
        
        bets[msg.sender][0] = _newGuess; //taking in the new guess
        bets[msg.sender][1] = msg.value - changeGuessFee; //deducting the fees.
        
        prizePool += changeGuessFee; //adding fees to prize pool
    }



    function endRound() public onlyOwner{
        require(roundActive == true, "A round should be active to end it!");
        require(block.timestamp >= roundEndTime, "Round time is still ON!");

        roundActive = false;

        distributePrizes();

    }

    function distributePrizes() private {

        bool hasWinner = false;
        uint16 totalWinners = 0;

        //we need to check if anyone won.

        for(uint i=0; i < players.length; i++){
            if(bets[players[i]][0] == toBeGuessed){
                hasWinner = true;
                totalWinners ++;
            }
        }

        if(hasWinner == true){
            uint256 prizeToWinners = prizePool/totalWinners;

            for(uint j=0; j < players.length; j++){
                if (bets[players[j]][0] == toBeGuessed) {
                    payable(players[j]).transfer(prizeToWinners); //we put money in their account
            }
        }
        }
        else{ //refund to everyone
            for(uint j=0; j < players.length; j++){
                payable(players[j]).transfer(bets[players[j]][1]);
            }
        }   
     } 
    
    }


