const dreamBidFee = artifacts.require("dreamBidFee")
const bidGame = artifacts.require("BidGame")
const gameRegistry = artifacts.require("gameRegistry")
const LibGame = artifacts.require("LibGame")
const sampleERC20 = artifacts.require("mintToken");
const LibCalculations = artifacts.require("LibCalculations")

var BigNumber = require('big-number');
const truffleAssert = require('truffle-assertions');
var moment = require('moment');
const ethers  = require("ethers");
const { BN, constants, expectEvent, shouldFail, time, expectRevert } = require('@openzeppelin/test-helpers');


contract("gameRegistry", async (accounts) => {

    let ProtocolFee, protocolOwner, Protocol, res, ERC20, bidStartTime, gameId1, gameId2,GameRegistry;

    let Bidder1 = accounts[1];
    let Bidder2 = accounts[2];
    let Bidder3 = accounts[3];

    bidStartTime = BigNumber(moment.now());
    bidEndTime =  BigNumber(moment.now()).plus(200);
    console.log("times",bidStartTime.toString(), "Hi", bidEndTime.toString())

    it("Should deploy contract", async() => {
        GameRegistry = await gameRegistry.deployed();
        BidGame = await bidGame.deployed();
        ERC20 = await sampleERC20.deployed();
        assert(GameRegistry * BidGame * ERC20 !== undefined || "" || null || NaN, "NFTLendingBorrowing contract was not deployed");
    })

    it("should set ProtocolFee", async () => {
        Protocol = await dreamBidFee.deployed();
        await Protocol.setProtocolFee(200);
        let ProtocolFee = await Protocol.protocolFee();
        let protocolOwner = await Protocol.getProtocolOwnerAddress();
        assert.equal(protocolOwner, accounts[0], "wrong Protocol Owner");
        assert.equal(ProtocolFee, 200, "wrong Protocol Fee");
    })

    it("should set competitor length", async() => {
        // GameRegistry = await gameRegistry.deployed();
        res = await GameRegistry.setCompetitorsLimit(3);
    })


    it("should let Protocol Owner create the game", async () => {
        
        await ERC20.mint(accounts[0], '10000000000');
        assert.notEqual(GameRegistry.address, null||undefined, "Game Registry unable to deployed")
        res = await GameRegistry.listGame(
            ERC20.address,
            100,
            0,
            bidEndTime,
            true,
            3,
            [["Hi"],["Shrish"],["Sonal"]]
        )
        gameId1 = res.logs[0].args.gameId.toNumber();
        assert.equal(gameId1, 1, "It must be one");
        

        res = await GameRegistry.listGame(
            ERC20.address,
            100,
            0,
            bidEndTime,
            false,
            3,
            [["Hi"],["Shrish"],["Sonal"]]
        )
        gameId2 = res.logs[0].args.gameId.toNumber();
        assert.equal(gameId2, 2, "It must be Two");
        
        await expectRevert(
            GameRegistry.listGame(
                ERC20.address,
                100,
                0,
                bidEndTime,
                false,
                4,
                [["Hi"],["Shrish"],["Sonal"],["Hello"]]
            ),
            "Competitors > CompetitorsLimit"
        )

        await expectRevert(
            GameRegistry.listGame(
                ERC20.address,
                100,
                0,
                bidEndTime,
                true,
                3,
                [["Hi"],["Shrish"],["Sonal"],["Hello"]]
            ),
            "Total Competitors"
        )
    })

    

    it("let add Bidder for gameId two", async() => {
        await expectRevert(
            GameRegistry.addBidders(2, Bidder1),
            "You can't add Bidder"
        )
    })
    console.log("times",bidStartTime.toString(), "Hi", bidEndTime.toString())

    it("let add Bidder for gameId one", async() => {
        res = await GameRegistry.addBidders(1, Bidder1);
        res = await GameRegistry.addBidders(1, Bidder2);
        res = await GameRegistry.addBidders(1, Bidder3);
    })

    it("let game owner remove the Bidder3", async() => {
        await GameRegistry.removeBidder(1,Bidder3)
    })

    it("let Bidders Bid on game1", async() => {
        await ERC20.mint(Bidder1, '10000000000');
        let balance = await ERC20.balanceOf(Bidder1);
        console.log("Bidder1 Balance",balance.toString())
        console.log("times",bidStartTime.toString(), "Hi", BigNumber(moment.now()).toString())
        await ERC20.approve(BidGame.address, 10000, { from: Bidder1 })
        let x = await ERC20.allowance(BidGame.address, Bidder1)
        // console.log("hj111j",x.toString())
        await BidGame.Bid(2,0,5000, {from: Bidder1})
        await BidGame.Bid(1,0,5000, {from: Bidder1})
    })

    it("let Bidder3 Bid on game1", async() => {
        await ERC20.mint(Bidder3, '10000000000');
        await ERC20.approve(BidGame.address, 6000, { from: Bidder3 })
        let x = await ERC20.allowance(BidGame.address, Bidder3)
        // console.log("hjj",x.toString())
        await expectRevert(
            BidGame.Bid(1,0,5000, {from: Bidder3}),
            "You are not Added as Bidder"
        )
    })

    
    
    




})