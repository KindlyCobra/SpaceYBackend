const truffleAssert = require('truffle-assertions');

const SpaceY = artifacts.require("SpaceYMock");

contract("SpaceY", accounts => {

    let owner = accounts[0];
    let instance;
    let universumSize = 1000;
    let startCosts = 100000;

    beforeEach(async function () {
        instance = await SpaceY.new(universumSize, startCosts, { from: owner });
        await instance.buyInitialPlanet({ from: accounts[1], value: startCosts });
    })

    it("should move units when enough static units on fromPlanet", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 10000);
        await instance.setPlanet(949, accounts[1], blockNumber, 0);
        let result = await instance.moveUnits(950, 949, 9000, { from: accounts[1] });

        truffleAssert.eventEmitted(result, "UnitsMoved", (ev) => {
            return ev.fromPlanetId == 950 && ev.toPlanetId == 949 && ev.player == accounts[1] && ev.units == 9000;
        });
    });

    it("should move units when enough dynamic units on fromPlanet", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number - 1;
        await instance.setPlanet(950, accounts[1], blockNumber, 0);
        await instance.setPlanet(999, accounts[1], blockNumber, 0);
        let result = await instance.moveUnits(950, 999, 10, { from: accounts[1] });

        truffleAssert.eventEmitted(result, "UnitsMoved", (ev) => {
            return ev.fromPlanetId == 950 && ev.toPlanetId == 999 && ev.player == accounts[1] && ev.units == 10;
        });
    });

    it("should not move units when having less units than send", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 0);
        await instance.setPlanet(999, accounts[1], blockNumber, 0);
        await truffleAssert.fails(
            instance.moveUnits(950, 949, 1000000, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });

    it("should not move units when not owning fromPlanet", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(949, accounts[1], blockNumber, 0);
        await truffleAssert.fails(
            instance.moveUnits(950, 949, 100, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });

    it("should not move units when not owning toPlanet", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 200);
        await truffleAssert.fails(
            instance.moveUnits(950, 949, 100, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });
});