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
        let result = await instance.setPlanet(950, accounts[1], blockNumber, 10000);
        console.info(instance.planets[950]);
        console.info(result);
        await instance.conquerPlanet(950, 949, 9000, { from: accounts[1] });
        assert.equal(instance.planets[950].owner, accounts[1]);
        assert.equal(instance.planets[950].units, 1000);

        assert.equal(instance.planets[949].owner, accounts[1]);
        assert.equal(instance.planets[949].blockNumber, blockNumber);
        assert.equal(instance.planets[949].units, 1000);
    });

});