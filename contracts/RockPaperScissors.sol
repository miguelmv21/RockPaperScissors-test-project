//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Dai.sol";


contract RockPaperScissors {
  uint256 public deposit;
  mapping(address => PlayerInfo) public players;
  GameInfo[] public games;
  uint256 public playerLength;
  uint256 public gameLength;
  ERC20 public tokenAddress;
  uint256 timeout = 1 days;

  
  struct PlayerInfo {
      address _address;
      uint256 balance;
      uint256 game;
      bool initialized;
  }

  struct GameInfo {
        address p1;
        address p2;
        bool accepted;
        bool ready;
        bool finalized;
        bytes32 p1_commit;
        bytes32 p2_commit;
        string p1_play;
        string p2_play;
        uint256 timeout;
  }

  event PlayerSignedUp(
        address indexed from
  );

  event ChallengeIssued(
        address indexed _from,
        address indexed _to,
        uint gameNum
  );
  event ChallengeAccepted(
        uint indexed gameNum
  );

  event GameFinalized(
        uint indexed gameNum
  );

  constructor(ERC20 _tokenAddress,uint256 _deposit) {
      tokenAddress=_tokenAddress;
      deposit=_deposit;
      gameLength=1;
      games.push(GameInfo(address(0x0),address(0x0),false,false,false,0,0,"","",0));
  }

  function signUp() public {
      require(!players[msg.sender].initialized,"Player already signed in");
      require(tokenAddress.balanceOf(msg.sender)>=deposit,"Not enough deposit");
      tokenAddress.transferFrom(msg.sender,address(this),deposit);
      playerLength++;
      players[msg.sender]=PlayerInfo(msg.sender,deposit,0,true);
      emit PlayerSignedUp(msg.sender);
  }

  function challenge(address _p2) public returns (uint) {
     require(msg.sender != _p2);
     require(players[msg.sender].initialized, "Player not signed up");
     require(players[msg.sender].game==0,"Player already in a game");
     require(players[_p2].initialized,"Challenged Player not signed up");
     require(players[_p2].game==0,"Challenged Player already in a game");
     games.push(GameInfo(address(msg.sender),_p2,false,false,false,0,0,"","",block.timestamp + timeout));
     gameLength++;
     players[msg.sender].game=gameLength;
     emit ChallengeIssued(msg.sender, _p2, gameLength);
     return gameLength;
  }

  function acceptChallenge(uint gameNum) public{
    GameInfo storage game=games[gameNum];
    require(players[msg.sender].game==0,"Player already in a game");
    require(game.p2==msg.sender,"Player not in this game");
    require(!game.accepted,"Challenge already accepted");
    game.accepted=true;
    game.timeout=block.timestamp + timeout;
    players[msg.sender].game=gameNum;
    emit ChallengeAccepted(gameNum);
  }

  function rejectChallenge(uint gameNum) public{
    GameInfo storage game=games[gameNum];
    require(game.p2==msg.sender,"Player not in this game");
    require(!game.accepted,"Game already accepted");
    players[game.p1].game=0;
  }

  function commitPlay(uint gameNum,bytes32 commit) public{
    GameInfo storage game = games[gameNum];
    require(!game.ready,"Game already played");
    require(msg.sender==game.p1 || msg.sender==game.p2,"Player not in game");
    if(msg.sender==game.p1){
      game.p1_commit=commit;
    }
    else{
      game.p2_commit=commit;
    }
    
    if(game.p1_commit != 0x0 && game.p2_commit != 0x0){
      game.ready=true;
    }
  }

  //reveals if player played rock, paper, or scissors
  //if both players have now revealed, settles the game
  function revealPlay(uint gameNum,bytes32 secret,string memory play) public{
    GameInfo storage game = games[gameNum];
    require(game.ready,"Game not yet finished");
    require(!game.finalized,"Game finalized");
    require(keccak256(abi.encodePacked(play)) == keccak256(abi.encodePacked("rock"))  || keccak256(abi.encodePacked(play)) == keccak256(abi.encodePacked("scissors"))  || keccak256(abi.encodePacked(play))==keccak256(abi.encodePacked("paper")) ,"invalid play");
    require(msg.sender==game.p1 || msg.sender==game.p2,"Player not in Game");
    bytes32 commit;
    if(msg.sender==game.p1){
      commit= game.p1_commit;
    }
    else{
      commit= game.p2_commit;
    }
     
    require(verifyHash(secret,play,commit),"play does not match committed value");


    if(msg.sender==game.p1){
      game.p1_play=play;
    }
    else{
      game.p2_play=play;
    }
    
    if(keccak256(abi.encodePacked(game.p1_play))!=keccak256(abi.encodePacked("")) && keccak256(abi.encodePacked(game.p2_play))!=keccak256(abi.encodePacked(""))){
      resolvePlay(gameNum);
      emit GameFinalized(gameNum);
    }
  }

  function resolvePlay(uint gameNum) internal{
    GameInfo memory game= games[gameNum];
    game.finalized=true;
    if(keccak256(abi.encodePacked(game.p1_play))==keccak256(abi.encodePacked(game.p2_play))){
        //draw
      }
      else{
        if(keccak256(abi.encodePacked(game.p1_play))==keccak256(abi.encodePacked("rock")) && keccak256(abi.encodePacked(game.p2_play))==keccak256(abi.encodePacked("scissors"))){
          //p1 wins
          players[game.p2].balance-=deposit;
          players[game.p1].balance+=deposit;
        }
        else if(keccak256(abi.encodePacked(game.p1_play))==keccak256(abi.encodePacked("scissors")) && keccak256(abi.encodePacked(game.p2_play))==keccak256(abi.encodePacked("paper"))){
          //p1 wins
          players[game.p2].balance-=deposit;
          players[game.p1].balance+=deposit;
        }
        else if(keccak256(abi.encodePacked(game.p1_play))==keccak256(abi.encodePacked("paper")) && keccak256(abi.encodePacked(game.p2_play))==keccak256(abi.encodePacked("rock"))){
          //p1 wins
          players[game.p2].balance-=deposit;
          players[game.p1].balance+=deposit;
        }
        else{
          //p2 wins
          players[game.p1].balance-=deposit;
          players[game.p2].balance+=deposit;
        }
      }
    players[game.p1].game=0;
    players[game.p2].game=0;
  }

  //player can withdraw IF:
  // - challenge was not accepted and timeout has passed
  // - other player has not played and timeout has passed
  // - other player has played but not confirmed his play and timeout has passed
  // - no current game and balance >0
  function withdraw() public{
    PlayerInfo storage player = players[msg.sender];
    require(player.balance>0,"no balance to withdraw");
    if(player.game==0){
      uint _balance = player.balance;
      player.balance=0;
      tokenAddress.transfer(msg.sender, _balance);
      player.initialized=false;
    }
    else{
      GameInfo memory game= games[player.game];
      if(block.timestamp>game.timeout){
        if(game.accepted && !game.ready){
          if(game.p1==msg.sender && game.p1_commit==0){
            revert();
          }
          if(game.p2==msg.sender && game.p2_commit==0){
            revert();
          }
        }
        if(game.ready && !game.finalized){
          if(game.p1==msg.sender && keccak256(abi.encodePacked(game.p1_play))==keccak256(abi.encodePacked(""))){
            revert();
          }
          if(game.p2==msg.sender && keccak256(abi.encodePacked(game.p2_play))==keccak256(abi.encodePacked(""))){
            revert();
          }
        }
        uint _balance =player.balance;
        player.balance=0;
        tokenAddress.transferFrom(address(this), msg.sender, _balance);
        player.game=0;
        player.initialized=false;
      }
      else{
        revert("Challenge still not timed out");
      }
    }
  }

  //verifies if Player really commited play
  function verifyHash (bytes32 secret, string memory play, bytes32 _root) public pure returns (bool) {
    bytes32 computedHash;
    computedHash = keccak256(abi.encodePacked(play, secret));
    return computedHash==_root;
  }
}