const SpaceY = artifacts.require("SpaceY");

module.exports = function (deployer) {
  deployer.deploy(SpaceY, 10000, 10);
};
