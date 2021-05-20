const { keccak256, bufferToHex } = require('ethereumjs-util');
const crypto = require('crypto');

async function main() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");
    
    console.log("Dai deployed to:", dai.address);

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1000);

    console.log("1000 dai transfered from: ",p1.address," to: ",p2.address);
    console.log("1000 dai transfered from: ",p1.address," to: ",p3.address);

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);

    await rps.deployed();
    console.log("RockPaperScissors deployed to:", rps.address);

    
    await dai.connect(p1).approve(rps.address,10);
    console.log("Dai approved from:",p1.address," to spend on:",rps.address,", amount:",10);
    await dai.connect(p2).approve(rps.address,10);
    console.log("Dai approved from:",p2.address," to spend on:",rps.address,", amount:",10);

    await rps.connect(p1).signUp();
    console.log(p1.address," signUp on ", rps.address);
    await rps.connect(p2).signUp();
    console.log(p2.address," signUp on ", rps.address);
    await rps.connect(p1).challenge(p2.address);
    console.log(p1.address," challenges ",p2.address, " on ",rps.address);
    await rps.connect(p2).acceptChallenge(1);
    console.log(p2.address," accepts ",p1.address,"'s challenge on ",rps.address);

    secret1=crypto.randomBytes(256);
    secret2=crypto.randomBytes(256);

    l1=[Buffer.from("rock"),keccak256(secret1)];
    commit1=keccak256(Buffer.concat(l1));
    await rps.connect(p1).commitPlay(1,commit1);
    console.log("Player1 commits:",commit1," on game1");

    l2=[Buffer.from("paper"),keccak256(secret2)];
    commit2=keccak256(Buffer.concat(l2));
    await rps.connect(p2).commitPlay(1,commit2);
    console.log("Player2 commits:",commit2," on game1");

    await rps.connect(p1).revealPlay(1,keccak256(secret1),"rock");
    console.log("Player1 reveals rock");

    await rps.connect(p2).revealPlay(1,keccak256(secret2),"paper");
    console.log("Player2 reveals paper");
    
    console.log("player2's Dai balance before withdrawal:",(await dai.connect(p2).balanceOf(p2.address)).toNumber());
    await rps.connect(p2).withdraw();
    console.log("player2's Dai balance after withdrawal:",(await dai.connect(p2).balanceOf(p2.address)).toNumber());
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });