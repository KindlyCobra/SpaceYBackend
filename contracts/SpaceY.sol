pragma solidity >=0.4.22 <0.9.0;

contract SpaceY {
    struct Planet {
        address owner;
        uint64 units;
    }

    struct PlanetStats {
        uint64 unitsCost;
        uint64 unitsCreationPerSecond;
    }

    uint32 public size;

    mapping(uint32 => Planet) planets;

    constructor(uint32 universeSize) public {
        size = universeSize;
    }

    modifier ownsPlanet(uint32 planetId, address person) {
        require(planets[planetId].owner == msg.sender, "Not owning planet");
        _;
    }

    event PlanetConquered(uint32 planetId, address indexed newOwner);

    function getPlanetStats(uint32 planetId)
        public
        view
        returns (uint64 unitsCost, uint64 unitsCreationPerSecond)
    {
        bytes32 hash_factor = keccak256(abi.encode(planetId));
        uint64 magnitute =
            size - (planetId + (planetId % uint8(hash_factor[0])));

        return (
            //magnitute + ((magnitute * uint8(hash_factor[0])) % magnitute),
            magnitute,
            (magnitute + uint8(hash_factor[1])) % magnitute
        );
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
        (uint64 unitCosts, uint64 unitsCreationPerSecond) =
            getPlanetStats(toPlanetId);
        require(planets[fromPlanetId].units >= sendUnitAmount);
        require(unitCosts <= sendUnitAmount);

        forceMoveUnits(fromPlanetId, toPlanetId, sendUnitAmount, unitCosts);
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
        uint64 unitCosts
    ) private {
        planets[fromPlanetId].units -= sendUnitAmount;
        sendUnitAmount -= unitCosts;
        planets[toPlanetId].owner = msg.sender;
        planets[toPlanetId].units = sendUnitAmount;
    }
}
