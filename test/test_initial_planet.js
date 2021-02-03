const SpaceY = artifacts.require("SpaceY");

contract("SpaceY", accounts => {

    let owner = accounts[0];
    let instance;
    let universumSize = 1000;
    let startCosts = 100000;

    beforeEach(async function () {
        instance = await SpaceY.new(universumSize, startCosts, { from: owner });
    })

    it("should be able to buy initial planet when address did not buy it yet", async () => {
        assert.equal(instance.playerStartBlocks[accounts[1]], undefined);
        let result = await instance.buyInitialPlanet({ from: accounts[1], value: startCosts });
        assert.equal(instance.playerStartBlocks[accounts[1]], result.blockNumber);
    });

    it("should not be able to buy initial planet when address did already buy before", async () => {
        await instance.buyInitialPlanet({ from: accounts[1], value: startCosts });
        let result = await instance.buyInitialPlanet({ from: accounts[1], value: startCosts });
        assert.equal()
    });

});