# RockPaperScissors

This RockPaperScissors smart contract lets any two players challenge each other and play on ethereum so long as they have the funds available as defined in the contract creation.

The flow of the game is as follows:
- Player1 challenges Player2.
- Player2 accepts challenge.
- Both Players generate off-chain a 32-byte secret key
- Both Players submit the keccak256 hash of the play {rock,paper,scissors} followed by their generated secret.
- Players now reveal their play by providing the secret and the play; The smart contracts attests that the hash generated is the same value committed beforehand.
- The winner is decided following the basic Rock,Paper,Scissors logic and players may now withdraw their funds (if any), or keep playing more games.



# Functions

## Constructor
params: _tokenAddress, _deposit
Creates the smart contract, defines the ERC20 token address and sets the deposit fee.

## signUp
params:-
Lets a player signUp on the dapp, depositing the fee.

## challenge
params:_p2
Challenges another player to play, provided they are NOT already in a gamey, and creates a new game.

## acceptChallenge
params:gameNum
Accepts challenge given gameNum.

## rejectChallenge
params:gameNum
Reject challenge given gameNum.
## commitPlay
params:gameNum,commit
Commits hash to game for later reveal.
## revealPlay
params:gameNum,secret,play={"rock","paper","scissors"}
reveals what the player has played by checking the hash of the secret and play arguments against the previously commited value.

## withdraw
player can withdraw IF:
 - challenge was not accepted and timeout has passed
 - other player has not played and timeout has passed
 - other player has played but not confirmed his play and timeout has passed
 - no current game and balance >0

params:-
Withdraws, if possible, the stored balance from previous game results to the player.

# Data Structs
## PlayerInfo
- address :  _address
- uint : balance
- uint : game
- bool : initialized

## GameInfo
- address : p1
- address : p2
- bool : accepted
- bool : ready
- bool : finalized
- bytes32 : p1_commit
- bytes32 : p2_commit
- string : p1_play
- string : p2_play