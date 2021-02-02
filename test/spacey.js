const SpaceY = artifacts.require("SpaceY");

contract("SpaceY", accounts => {
    it("get correct planet stats", () =>
        SpaceY.deployed(1000)
            .then(instance => instance.getPlanetStats.call(500))
            .then(result => {
                console.info(result.unitsCost.toNumber());
            }));
});