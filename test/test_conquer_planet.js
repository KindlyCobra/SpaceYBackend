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

    it("should conquer planet when enough static units on fromPlanet", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 10000);
        let result = await instance.conquerPlanet(950, 949, 9000, { from: accounts[1] });

        truffleAssert.eventEmitted(result, "PlanetConquered", (ev) => {
            return ev.planetId == 949 && ev.player == accounts[1] && ev.units == 6399;
        });
        truffleAssert.eventEmitted(result, "UnitsMoved", (ev) => {
            return ev.fromPlanetId == 950 && ev.toPlanetId == 949 && ev.player == accounts[1] && ev.units == 9000;
        });

    });

    it("should conquer planet when enough dynamic units on fromPlanet", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 0);
        let result = await instance.conquerPlanet(950, 999, 10, { from: accounts[1] });

        truffleAssert.eventEmitted(result, "PlanetConquered", (ev) => {
            return ev.planetId == 999 && ev.player == accounts[1] && ev.units == 9;
        });
        truffleAssert.eventEmitted(result, "UnitsMoved", (ev) => {
            return ev.fromPlanetId == 950 && ev.toPlanetId == 999 && ev.player == accounts[1] && ev.units == 10;
        });
    });

    it("should not conquer planet when sending less units than costs", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 0);
        await truffleAssert.fails(
            instance.conquerPlanet(950, 949, 1, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });

    it("should not conquer planet when having less units than send", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 0);
        await truffleAssert.fails(
            instance.conquerPlanet(950, 949, 1000000, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });

    it("should not conquer planet when not owning fromPlanet", async () => {
        await truffleAssert.fails(
            instance.conquerPlanet(950, 949, 100, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });

    it("should not conquer planet when toPlanet is owned by other player", async () => {
        await instance.buyInitialPlanet({ from: accounts[2], value: startCosts });

        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 100000);
        await instance.setPlanet(900, accounts[2], blockNumber, 100000);
        await instance.conquerPlanet(900, 940, 10000, { from: accounts[2] });
        await truffleAssert.fails(
            instance.conquerPlanet(950, 940, 10000, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });

    it("should not conquer planet when toPlanet is already owned", async () => {
        await instance.buyInitialPlanet({ from: accounts[2], value: startCosts });

        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(950, accounts[1], blockNumber, 100000);
        await instance.conquerPlanet(950, 949, 10000, { from: accounts[1] });
        await truffleAssert.fails(
            instance.conquerPlanet(950, 949, 10000, { from: accounts[1] }),
            truffleAssert.ErrorType.REVERT);
    });
});