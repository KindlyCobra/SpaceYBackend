pragma solidity >=0.4.22 <0.9.0;

contract SpaceY {
    struct Planet {
        address owner;
        uint256 conquerBlockNumber;
        int128 units;
    }

    address payable public owner;

    uint256 public startCosts;

    uint32 public universeSize;

    mapping(uint32 => Planet) public planets;
    mapping(address => uint256) public playerStartBlocks;

    constructor(uint32 size, uint256 startFee) public {
        universeSize = size;
        startCosts = startFee;
    }

    modifier ownsPlanet(uint32 planetId, address person) {
        require(planets[planetId].owner == msg.sender, "Not owning planet");
        _;
    }

    event PlanetConquered(uint32 planetId, address indexed newOwner);

    function buyInitialPlanet() public payable {
        require(
            msg.value >= startCosts,
            "The transaction does not contain enought value to cover the start costs"
        );
        require(
            playerStartBlocks[msg.sender] == 0,
            "The address already bought an initial planet"
        );
        playerStartBlocks[msg.sender] = block.number;
    }

    function getPlanetStats(uint32 planetId)
        public
        view
        returns (uint64 unitsCost, uint64 unitsCreationRate)
    {
        uint64 magnitute = (universeSize - planetId)**2;

        return (magnitute, magnitute / 100);
    }

    function getUnitsOnPlanet(uint32 planetId)
        public
        view
        returns (int128 units)
    {
        Planet memory planet = planets[planetId];
        if (planet.owner == address(0x0)) {
            return 0;
        }
        uint256 timeDif = block.number - planet.conquerBlockNumber;
        (uint64 _, uint64 unitsCreationRate) = getPlanetStats(planetId);
        return planet.units + int128(timeDif * unitsCreationRate);
    }

    function conquerPlanet(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount
    )
        public
        ownsPlanet(toPlanetId, msg.sender)
        ownsPlanet(fromPlanetId, address(0x0))
    {
        (uint64 unitsCost, uint64 _) = getPlanetStats(toPlanetId);
        require(planets[fromPlanetId].units >= sendUnitAmount);
        require(unitsCost <= sendUnitAmount);

        planets[toPlanetId] = Planet(owner, block.number, 0);

        forceMoveUnits(fromPlanetId, toPlanetId, sendUnitAmount, unitsCost);
    }

    function moveUnits(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount
    )
        public
        ownsPlanet(toPlanetId, msg.sender)
        ownsPlanet(fromPlanetId, msg.sender)
    {
        require(planets[fromPlanetId].units >= sendUnitAmount);
        forceMoveUnits(fromPlanetId, toPlanetId, sendUnitAmount, 0);
    }

    function forceMoveUnits(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount,
        uint64 unitsCost
    ) private {
        planets[fromPlanetId].units -= sendUnitAmount;
        sendUnitAmount -= unitsCost;
        planets[toPlanetId].units = sendUnitAmount;
    }
}
