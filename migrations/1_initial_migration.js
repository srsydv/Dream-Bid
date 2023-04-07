const dreamBidFee = artifacts.require("dreamBidFee")
const BidGame = artifacts.require("BidGame")
const gameRegistry = artifacts.require("gameRegistry")
const LibGame = artifacts.require("LibGame")
const lendingToken = artifacts.require("mintToken")
const LibCalculations = artifacts.require("LibCalculations")

module.exports = async function(deployer) {
    
    await deployer.deploy(dreamBidFee);
    var protocolFee = await dreamBidFee.deployed();

    await deployer.deploy(LibGame);
    deployer.link(LibGame, [gameRegistry]);

    await deployer.deploy(gameRegistry, protocolFee.address);
    var GameRegistry = await gameRegistry.deployed();

    await deployer.deploy(BidGame, GameRegistry.address, protocolFee.address);
    await BidGame.deployed();

    await deployer.deploy(lendingToken, 100000000000)


}