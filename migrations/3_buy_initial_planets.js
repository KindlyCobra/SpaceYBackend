const SpaceY = artifacts.require("SpaceY");

module.exports = async function (deployer, network, accounts) {
  if (network == "development") {
    deployer.deploy(SpaceY, { overwrite: false }).then(async function (instance) {
      console.info("Working with contract @ " + instance.address);
      for (i = 0; i < 5; i++) {
        let result = await instance.buyInitialPlanet({ from: accounts[i], value: 1000 });
        if (!result.receipt.status) {
          console.info(result);
          console.info("Error while buying initial planet for " + i);
        } else {
          console.info("Bought initial planet for " + accounts[i] + " @ " + result.tx);
        }
      }
    });
  } else {
    console.info("Buying initial planets is only valid on network \"development\", not " + network);
  }
};
