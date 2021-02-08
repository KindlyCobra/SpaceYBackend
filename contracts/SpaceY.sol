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
    mapping(address => Planet) public startPlanets;

    constructor(uint32 size, uint256 startFee) public {
        universeSize = size;
        startCost = startFee;
        owner = msg.sender;
    }

    modifier ownsPlanet(uint32 planetId, address person) {
        if (planetId != universeSize) {
            require(planets[planetId].owner == person, "Not owning planet");
        } else {
            require(
                startPlanets[person].owner != address(0x0),
                "Not owning origin planet"
            );
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
                startPlanets[msg.sender].owner != address(0x0),
                "Can't have units on start planet if not an active player"
            );
            return (0, 1);
        }
        uint64 magnitute = (universeSize - planetId)**2;
        uint64 productionRate = magnitute / 100;
        if (productionRate <= 0) {
            productionRate = 1;
        }
        return (magnitute, productionRate);
    }

    function getUnitsOnPlanet(uint32 planetId)
        public
        view
        planetExists(planetId)
        returns (uint64 units)
    {
        Planet memory planet;
        if (planetId == universeSize) {
            planet = startPlanets[msg.sender];
            require(
                planet.owner != address(0x0),
                "Player does not own origin planet"
            );
        } else {
            planet = planets[planetId];
            if (planet.owner == address(0x0)) {
                return 0;
            }
        }
        uint256 blockDelta = block.number - planet.conquerBlockNumber;
        (uint64 _, uint64 unitsCreationRate) = getPlanetStats(planetId);
        uint64 amount =
            uint64(planet.units + int128(blockDelta * unitsCreationRate));
        return amount;
    }

    function getPlanet(uint32 planetId)
        public
        view
        planetExists(planetId)
        returns (
            address owner,
            uint256 conquerBlockNumber,
            int128 units
        )
    {
        Planet memory planet;
        if (planetId == universeSize) {
            if (startPlanets[msg.sender].owner != address(0x0)) {
                planet = startPlanets[msg.sender];
            } else {
                return (address(0x0), 0, 0);
            }
        } else {
            planet = planets[planetId];
        }
        return (planet.owner, planet.conquerBlockNumber, planet.units);
    }

    function buyInitialPlanet() external payable {
        require(
            msg.value >= startCost,
            "The transaction does not contain enought value to cover the start costs"
        );
        require(
            startPlanets[msg.sender].owner == address(0x0),
            "The address already bought an initial planet"
        );
        startPlanets[msg.sender] = Planet(msg.sender, block.number, 0);
        emit InitialPlanetBought(msg.sender);
    }

    function conquerPlanet(
        uint32[] calldata fromPlanetIds,
        uint32 toPlanetId,
        uint64[] calldata sendUnitAmounts
    ) external {
        require(
            fromPlanetIds.length == sendUnitAmounts.length,
            "Length of planetIds have to match length of sendUnits"
        );
        uint64 totalSendAmount = sendUnitAmounts[0];
        for (uint32 i = 1; i < fromPlanetIds.length; i++) {
            moveUnits(fromPlanetIds[i], fromPlanetIds[0], sendUnitAmounts[i]);
            totalSendAmount += sendUnitAmounts[i];
        }
        conquerPlanetSingle(fromPlanetIds[0], toPlanetId, totalSendAmount);
    }

    function conquerPlanetSingle(
        uint32 fromPlanetId,
        uint32 toPlanetId,
        uint64 sendUnitAmount
    ) private ownsPlanet(fromPlanetId, msg.sender) unownedPlanet(toPlanetId) {
        (uint64 unitsCost, uint64 _) = getPlanetStats(toPlanetId);
        require(
            getUnitsOnPlanet(fromPlanetId) >= sendUnitAmount,
            "Not enough units on fromPlanet to fullfill sendAmount"
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
        public
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
        if (fromPlanetId == universeSize) {
            planets[fromPlanetId].units -= sendUnitAmount;
        } else {
            startPlanets[msg.sender].units -= sendUnitAmount;
        }
        uint64 remainingUnits = sendUnitAmount - unitsCost;
        planets[toPlanetId].units = remainingUnits;
        emit UnitsMoved(fromPlanetId, toPlanetId, msg.sender, sendUnitAmount);
    }
}
