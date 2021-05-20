const { expect } = require("chai");

describe("RockPaperScissors", function() {
  it("Should create a RockPaperScissors dapp with deposit fee = 10 using token Dai", async function() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1);

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);
    

    await rps.deployed();
  });

  it("Should allow players 1 and 2 (who have deposits) to signUp", async function() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1);

   

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);

    await rps.deployed();

    dai.connect(p1).approve(rps.address,10);
    dai.connect(p2).approve(rps.address,10);

    await rps.connect(p1).signUp();
    await rps.connect(p2).signUp();
  });

  it("Should NOT allow player 3 to signUp because he has no deposit", async function() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1);

   

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);

    await rps.deployed();

    dai.connect(p3).approve(rps.address,10);
    dai.connect(p2).approve(rps.address,10);

    await (expect(rps.connect(p3).signUp()).to.be.reverted);

  });

  it("Should NOT allow player1 to signUp twice", async function() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1);

   

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);

    await rps.deployed();

    dai.connect(p1).approve(rps.address,20);
    dai.connect(p2).approve(rps.address,10);

    await(rps.connect(p1).signUp());
    await (expect(rps.connect(p1).signUp()).to.be.reverted);

  });

  it("Should NOT let player3 accept a challenge from player1 to player2", async function() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1000);

   

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);

    await rps.deployed();

    dai.connect(p1).approve(rps.address,10);
    dai.connect(p2).approve(rps.address,10);
    dai.connect(p3).approve(rps.address,10);

    await(rps.connect(p1).signUp());
    await(rps.connect(p2).signUp());
    await(rps.connect(p3).signUp());
    await(rps.connect(p1).challenge(p2.address));
    await (expect(rps.connect(p3).acceptChallenge(1)).to.be.reverted);
  });

  it("Should not let player1 withdraw his balance until player2 goes rogue, and timeout has passed", async function() {
    const Dai = await ethers.getContractFactory("Dai");
    const dai = await Dai.deploy(400000,"Dai",2,"DAI");

    [p1,p2,p3] = await ethers.getSigners();
    dai.connect(p1).transfer(p2.address,1000);
    dai.connect(p1).transfer(p3.address,1000);

   

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rps = await RockPaperScissors.deploy(dai.address,10);

    await rps.deployed();

    dai.connect(p1).approve(rps.address,10);
    dai.connect(p2).approve(rps.address,10);
    dai.connect(p3).approve(rps.address,10);

    await(rps.connect(p1).signUp());
    await(rps.connect(p2).signUp());
    await(rps.connect(p3).signUp());
    await(rps.connect(p1).challenge(p2.address));
    await(rps.connect(p2).acceptChallenge(1));
    
    await expect((rps.connect(p1).withdraw())).to.be.reverted;
  });

  /*
  it("", async function() {

  });

  it("Should create a RockPaperScissors dapp with deposit fee = 10 using token 0x0", async function() {

  });

  */
});
