const dreamBidFee = artifacts.require("dreamBidFee")
const BidGame = artifacts.require("BidGame")
const gameRegistry = artifacts.require("gameRegistry")
const LibGame = artifacts.require("LibGame")
const SampleERC20 = artifacts.require("mintToken");
const LibCalculations = artifacts.require("LibCalculations")

var BigNumber = require('big-number');
const truffleAssert = require('truffle-assertions');
var moment = require('moment');
const ethers  = require("ethers");
const { BN, constants, expectEvent, shouldFail, time, expectRevert } = require('@openzeppelin/test-helpers');


contract("gameRegistry", async (accounts) => {

    let ProtocolFee, protocolOwner, Protocol, res, ERC20, bidStartTime, gameId1, gameId2;
    let Bidder = accounts[1];
    // ERC20 = await SampleERC20.deployed();
    bidStartTime = BigNumber(moment.now());
    bidEndTime =  BigNumber(moment.now()).plus(200);
    console.log("times",bidStartTime.toString(), "Hi", bidEndTime.toString())

    it("should set ProtocolFee", async () => {
        Protocol = await dreamBidFee.deployed();
        await Protocol.setProtocolFee(200);
        let ProtocolFee = await Protocol.protocolFee();
        let protocolOwner = await Protocol.getProtocolOwnerAddress();
        assert.equal(protocolOwner, accounts[0], "wrong Protocol Owner");
        assert.equal(ProtocolFee, 200, "wrong Protocol Fee");
    })

    it("should set competitor length", async() => {
        GameRegistry = await gameRegistry.deployed();
        res = await GameRegistry.setCompetitorsLimit(3);
    })


    it("should let Protocol Owner create the game", async () => {
        ERC20 = await SampleERC20.deployed();
        GameRegistry = await gameRegistry.deployed();
        await ERC20.mint(accounts[0], '10000000000');
        assert.notEqual(GameRegistry.address, null||undefined, "Game Registry unable to deployed")
        res = await GameRegistry.listGame(
            ERC20.address,
            100,
            bidStartTime,
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
            bidStartTime,
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
                bidStartTime,
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
                bidStartTime,
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
            GameRegistry.addBidders(1, Bidder),
            "You can't add Bidder"
        )
        // res = await GameRegistry.addBidders(1, Bidder);
    })




})