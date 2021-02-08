const SpaceY = artifacts.require("SpaceY");

module.exports = function (deployer) {
  deployer.deploy(SpaceY, 1000, 10);
};
