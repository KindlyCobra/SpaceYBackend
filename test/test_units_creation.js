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

    it("should calculate proper units on planet after 1 block when having no moved units", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(100, accounts[1], blockNumber, 0);
        let planetStats = await instance.getPlanetStats(100);
        let result = await instance.getUnitsOnPlanet(100);
        assert.equal(result.toNumber(), planetStats.unitsCreationRate.toNumber());
    });

    it("should calculate proper units on planet after 2 block when having no moved units", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number - 1;
        await instance.setPlanet(100, accounts[1], blockNumber, 0);
        let planetStats = await instance.getPlanetStats(100);
        let result = await instance.getUnitsOnPlanet(100);
        assert.equal(result.toNumber(), planetStats.unitsCreationRate.toNumber() * 2);
    });

    it("should calculate proper units on planet after 1 block when having moved units", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(100, accounts[1], blockNumber, 100);
        let planetStats = await instance.getPlanetStats(100);
        let result = await instance.getUnitsOnPlanet(100);
        assert.equal(result.toNumber(), planetStats.unitsCreationRate.toNumber() + 100);
    });

    it("should calculate proper units on planet after 1 block when having negative moved units", async () => {
        let blockNumber = (await web3.eth.getBlock("latest")).number;
        await instance.setPlanet(100, accounts[1], blockNumber, - 100);
        let planetStats = await instance.getPlanetStats(100);
        let result = await instance.getUnitsOnPlanet(100);
        assert.equal(result.toNumber(), planetStats.unitsCreationRate.toNumber() - 100);
    });

});