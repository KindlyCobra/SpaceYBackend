pragma solidity >=0.4.22 <0.9.0;

contract SpaceY {
    struct Planet {
        address owner;
        uint256 conquerBlockNumber;
        int128 units;
    }

    address payable public owner;

    uint256 public startCost;

    uint32 public universeSize;

    mapping(uint32 => Planet) public planets;
    mapping(address => uint256) public playerStartBlocks;

    constructor(uint32 size, uint256 startFee) public {
        universeSize = size;
        startCost = startFee;
        owner = msg.sender;
    }

    modifier ownsPlanet(uint32 planetId, address person) {
        if (planetId != universeSize) {
            require(planets[planetId].owner == person, "Not owning planet");
        } else {
            require(playerStartBlocks[person] != 0, "Not owning origin planet");
        }
        _;
    }

    modifier unownedPlanet(uint32 planetId) {
        require(
            planets[planetId].owner == address(0x0),
            "Planet is not unowned"
        );
        _;
    }

    modifier planetExists(uint32 planetId) {
        require(planetId <= universeSize);
        _;
    }

    event InitialPlanetBought(address indexed player);
    event PlanetConquered(
        uint32 planetId,
        address indexed player,
        uint64 units
    );
    event UnitsMoved(
        uint32 indexed fromPlanetId,
        uint32 indexed toPlanetId,
        address indexed player,
        uint64 units
    );

    function getPlanetStats(uint32 planetId)
        public
        view
        planetExists(planetId)
        returns (uint64 unitsCost, uint64 unitsCreationRate)
    {
        if (planetId == universeSize) {
            require(
                playerStartBlocks[msg.sender] != 0,
                "Can't have units on start planet if not an active player"
            );
            return (0, 1);
        }
        uint64 magnitute = (universeSize - planetId)**2;

        return (magnitute, magnitute / 100);
    }

    function getUnitsOnPlanet(uint32 planetId)
        public
        view
        planetExists(planetId)
        returns (uint64 units)
    {
        uint256 conquerBlockNumber;
        int128 staticUnits;
        if (planetId == universeSize) {
            conquerBlockNumber = playerStartBlocks[msg.sender];
            staticUnits = 0;
        } else {
            Planet storage planet = planets[planetId];
            if (planet.owner == address(0x0)) {
                return 0;
            }
            conquerBlockNumber = planet.conquerBlockNumber;
            staticUnits = planet.units;
        }
        uint256 blockDelta = block.number - conquerBlockNumber;
        (uint64 _, uint64 unitsCreationRate) = getPlanetStats(planetId);
        uint64 amount =
            uint64(staticUnits + int128(blockDelta * unitsCreationRate));
        return amount;
    }

    function buyInitialPlanet() external payable {
        require(
            msg.value >= startCost,
            "The transaction does not contain enought value to cover the start costs"
        );
        require(
            playerStartBlocks[msg.sender] == 0,
            "The address already bought an initial planet"
        );
        playerStartBlocks[msg.sender] = block.number;
        emit InitialPlanetBought(msg.sender);
    }

    function conquerPlanet(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount
    ) external ownsPlanet(fromPlanetId, msg.sender) unownedPlanet(toPlanetId) {
        (uint64 unitsCost, uint64 _) = getPlanetStats(toPlanetId);
        require(
            getUnitsOnPlanet(fromPlanetId) >= sendUnitAmount,
            "Not enough units on fromPlanet"
        );
        require(
            unitsCost <= sendUnitAmount,
            "The sended unit amount is smaller than the cost"
        );

        planets[toPlanetId] = Planet(msg.sender, block.number, 0);

        emit PlanetConquered(
            toPlanetId,
            msg.sender,
            sendUnitAmount - unitsCost
        );
        forceMoveUnits(fromPlanetId, toPlanetId, sendUnitAmount, unitsCost);
    }

    function moveUnits(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount
    )
        external
        ownsPlanet(toPlanetId, msg.sender)
        ownsPlanet(fromPlanetId, msg.sender)
    {
        require(
            getUnitsOnPlanet(fromPlanetId) >= sendUnitAmount,
            "Not enough units on fromPlanet"
        );
        forceMoveUnits(fromPlanetId, toPlanetId, sendUnitAmount, 0);
    }

    function forceMoveUnits(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount,
        uint64 unitsCost
    ) private {
        planets[fromPlanetId].units -= sendUnitAmount;
        uint64 remainingUnits = sendUnitAmount - unitsCost;
        planets[toPlanetId].units = remainingUnits;
        emit UnitsMoved(fromPlanetId, toPlanetId, msg.sender, sendUnitAmount);
    }
}
