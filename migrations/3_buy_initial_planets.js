const SpaceY = artifacts.require("SpaceY");

module.exports = async function (deployer, network, accounts) {
  if (network == "development") {
    deployer.deploy(SpaceY, { overwrite: false }).then(async function (instance) {
      console.info("Working with contract @ " + instance.address);
      for (i = 0; i < 2; i++) {
        await instance.buyInitialPlanet({ from: accounts[i], value: 1000 });
        console.info("Bought initial planet for " + accounts[i]);
      }
    });
  } else {
    console.info("Buying initial planets is only valid on network \"development\", not " + network);
  }
};
