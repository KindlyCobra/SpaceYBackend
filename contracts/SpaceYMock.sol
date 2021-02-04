pragma solidity >=0.4.22 <0.9.0;

import "./SpaceY.sol";

contract SpaceYMock is SpaceY {
    constructor(uint32 size, uint256 startFee) public SpaceY(size, startFee) {}

    function setPlanet(
        uint32 planetId,
        address owner,
        uint256 blockNumber,
        int128 units
    ) external {
        planets[planetId] = Planet(owner, blockNumber, units);
    }
}
