//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract Bingo {

    event DrawNumber (uint number, string message);

    address public owner;
    uint256 public buyIn = 1;
    uint256 public maxBingoNumbers = 10;
    uint[]  public numbersDrawn;
    bool public signUpOpen = true;
    address public isWinner;
    BingoCard[] bingocard;
    address[] players;

    mapping (address => BingoCard) playerCards;
    
    struct BingoCard {
        uint[] numbers;
    }

    constructor() {
        owner = msg.sender;
        // buyIn = _buyIn;
        // maxBingoNumbers = _maxBingoNumbers;
    }

    // SET-UP - WHITLIST FUNCTION
    // -------------------------------------------------------------
    // Players can enter the bingo whitelist by paying buyIn amount
    // If payment is enough players get assigned their bingo numbers
    function signUp() external payable {
        require(msg.value >= buyIn, "not enough buy in");
        require(signUpOpen, "Bingo started already");
        uint[] memory _numbers = new uint[](maxBingoNumbers);
        _numbers = generateBingoNumbers();
        bingocard.push(BingoCard(_numbers));
        players.push(msg.sender);
        playerCards[msg.sender] = BingoCard(_numbers);
    }

    // GET ALL PLAYERS THAT HAVE SIGNED UP - GET FUNCTION
    // -------------------------------------------------------------
    // Returns an array of all the players 
    function getPlayers() public view returns(address[] memory){
        require(players.length != 0, "No players yet");
        address[] memory totalPlayers = new address[](players.length);
        for(uint i=0; i<=players.length-1;i++){
            totalPlayers[i] = players[i];
        }
        return totalPlayers;
    }

    // GET BINGO NUMBERS OF A PLAYER - GET FUNCTION
    // -------------------------------------------------------------
    // Return an array of bingo numbers with owner as input
    function getBingoNumbers(address _ownerBingCard) public view returns(uint[] memory){
        uint[] memory bingoNumbers = new uint[](maxBingoNumbers);
        bingoNumbers = playerCards[_ownerBingCard].numbers;
        return bingoNumbers;
    }

    // GET BINGO NUMBERS THAT ARE DRAWN THIS ROUND- GET FUNCTION
    // -------------------------------------------------------------
    // Returns an array of all the numbers that have been drawn this round of bingo
    function listNumbersDrawn() public view returns(uint[] memory ){
        require(numbersDrawn.length!=0, "No numbers drawn yet");
        uint[] memory listOfNumbers = new uint[](numbersDrawn.length);
        for(uint i=0; i<=numbersDrawn.length-1;i++){
            listOfNumbers[i] = numbersDrawn[i];
        }
        return listOfNumbers;
    }

    // CREATE A RANDOM NUMBER - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a randomNumber (Can be replaced by Chainlink)
    function randomNumber(uint _input) internal returns(uint256){
      uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number + (_input * 1 minutes)
      )));
      uint number = (seed - ((seed / 100) * 100));
      emit DrawNumber(number, "Is the number drawn!");
      return number;
    }

    // CREATE RANGE OF NUMBERS FOR BINGO CARD - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a set 5 bingo numbers for 1 owner
    function generateBingoNumbers() internal returns(uint[] memory){
        uint[] memory bingoNumbers = new uint[](maxBingoNumbers);
        for(uint i=0; i<=maxBingoNumbers-1;i++){
            bingoNumbers[i] = randomNumber(i+1);
        }
        return bingoNumbers;
    }

    // CREATE A RANDOM NUMBER FOR DRAW - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Draw number function when playing bingo
    function drawNumber() public returns(uint _number){    
        signUpOpen = false;
        uint[] memory draw = new uint[](maxBingoNumbers);
        draw = generateBingoNumbers();
        if(numbersDrawn.length !=0){
            for(uint i=0; i<=numbersDrawn.length-1; i++){
                for(uint x=0; x<=draw.length-1; x++){
                    if(draw[x]==numbersDrawn[i]){
                        continue;
                    }else{
                        _number = draw[x];
                        numbersDrawn.push(_number);
                        checkNumberHit(_number);
                        return _number;
                    }
                }
            }
        }
        _number = draw[0];
        numbersDrawn.push(_number);
        checkNumberHit(_number);
        return _number;
    }

    // CHECK IF PLAYER HAS HIT THE DRAW NUMBER - CHECK FUNCTIONS
    // -------------------------------------------------------------
    // Check each player's bingo card to see if the draw number is a hit
    // If there is a hit, change the number to 100 (value of a hit)
    function checkNumberHit(uint _numberDrawn) public {
      for(uint i=0; i<=players.length-1;i++){
        uint[] memory bingoNumbers = new uint[](maxBingoNumbers);
        bingoNumbers = getBingoNumbers(players[i]);
        for(uint x=0; x<=bingoNumbers.length-1;x++){
          if(bingoNumbers[x]==_numberDrawn){
            playerCards[players[i]].numbers[x] = 100;
          }
          
        }
      }
    }

    // CHECK IF PLAYER HAS BINGO - CHECK FUNCTIONS
    // -------------------------------------------------------------
    // Check each player's bingo card to see if they have bingo
    // Return true if there is a player with bingo
    function checkBingo() public returns(address _bingoWinner, bool _winner){
      require(players.length!=0);
      for(uint256 i=0; i<=players.length-1;i++){
        uint bingo;
        uint[] memory bingoNumbers = new uint[](maxBingoNumbers);
        bingoNumbers = getBingoNumbers(players[i]);
        for(uint x=0; x<=bingoNumbers.length-1;x++){
          if(bingoNumbers[x]==100){
            bingo += 1;
          } 
        }
        if(bingo==5 && players[i] != 0x0000000000000000000000000000000000000000){
            isWinner= players[i];
            return (players[i], true);
        }
        else{
            return (0x0000000000000000000000000000000000000000, false);
        }
      }
    }

    // IF THERE IS A WINNER PAY THEM - PAY FUNCTIONS
    // -------------------------------------------------------------
    // Check each player's bingo card to see if they have bingo
    // Return true if there is a player with bingo 
    function payWinner(address _bingoWinner) public payable {
        require(isWinner == _bingoWinner, "You are not the winner");
        (bool success, ) = payable(_bingoWinner).call{value: address(this).balance}('');
        require(success);
    }
    
    // UNLOCK FUNDS FROM CONTRACT - PAY FUNCTIONS
    // -------------------------------------------------------------
    // Get your funds back when testing on testnet
    function withdraw(address _receiver) external payable {
        require(msg.sender == owner);
        (bool success, ) = _receiver.call{value: address(this).balance}("");
        require(success);
    }

    // PLAY BINGO - GAME FUNCTION
    // -------------------------------------------------------------
    // While loop to play bingo
    function playBingo() public{
      bool bingo = true;
      while(bingo){ 
        uint number = drawNumber();
        checkNumberHit(number);
        (address _bingoWinner, bool _winner) = checkBingo();
        if(_winner){
          bingo=false;
        //   payWinner(_bingoWinner);
        }
      }  
    }
}