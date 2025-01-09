// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract drugTracker {
    // Enum to represent different statuses of drugs
    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

    // Struct to represent a drug's details
    struct Drug {
        string name; // Name of the drug
        uint quantity; // Quantity of the drug
        Status status; // Status of the drug (Pending, Shipped, etc.)
        string location; // Location where the drug is stored
        uint expirationDate; // Expiration date (timestamp) of the drug
        address owner; // Owner address of the drug
    }

    // Struct to represent the inventory of a specific owner
    struct Inventory {
        uint count; // Total count of drugs owned by the owner
        string location; // Location where the owner's drugs are stored
    }

    // Mapping to track drugs by their unique ID
    mapping(uint => Drug) public drugs;
    // Mapping to track inventory of each owner by their address
    mapping(address => Inventory) public owners;

    // Admin address that controls the contract
    address public admin;

    // A counter to keep track of the total number of drugs
    uint public drugCount;

    // Constructor to set the admin address as the contract deployer
    constructor() {
        admin = msg.sender; // The address that deploys the contract is the admin
    }

    // Modifier to restrict certain functions to the admin only
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    // Function to add a new drug (only accessible by the admin)
    function addDrug(
        string memory _name,
        uint _quantity,
        Status _status,
        string memory _location,
        uint _expirationDate
    ) public onlyAdmin {
        drugCount++; // Increment the drug counter
        // Add the new drug to the mapping using drugCount as its unique ID
        drugs[drugCount] = Drug({
            name: _name,
            quantity: _quantity,
            status: _status,
            location: _location,
            expirationDate: _expirationDate,
            owner: admin // Initially, the drug is owned by the admin
        });
        // Update the admin's inventory to include the new drug
        owners[admin].count += _quantity;
        owners[admin].location = _location; // Set the location for the admin
    }

    // Function to update the status of a drug (only accessible by the admin)
    function updateDrugStatus(uint _drugId, Status _status) public onlyAdmin {
        Drug storage drug = drugs[_drugId]; // Get the drug by its ID
        drug.status = _status; // Update the drug's status
    }

    // Function to transfer ownership of a drug from one owner to another
    function transferDrug(
        uint _drugId,
        address _newOwner,
        uint _quantity
    ) public {
        Drug storage drug = drugs[_drugId]; // Get the drug by its ID
        require(
            msg.sender == drug.owner,
            "You are not the owner of this drug."
        ); // Ensure the caller is the owner
        require(drug.quantity >= _quantity, "Not enough quantity to transfer."); // Ensure sufficient quantity for transfer

        // Update the drug's quantity and ownership
        drug.quantity -= _quantity; // Decrease the drug's quantity
        owners[drug.owner].count -= _quantity; // Decrease the owner's inventory count
        drug.owner = _newOwner; // Set the new owner
        owners[_newOwner].count += _quantity; // Increase the new owner's inventory count
    }

    // Function to update the quantity of a drug (only accessible by the admin)
    function updateDrugQuantity(
        uint _drugId,
        uint _newQuantity
    ) public onlyAdmin {
        Drug storage drug = drugs[_drugId]; // Get the drug by its ID
        owners[drug.owner].count -= drug.quantity; // Decrease the owner's inventory by the old quantity
        drug.quantity = _newQuantity; // Update the drug's quantity
        owners[drug.owner].count += _newQuantity; // Increase the owner's inventory by the new quantity
    }

    // Function to update the location of a drug (only accessible by the admin)
    function updateDrugLocation(
        uint _drugId,
        string memory _newLocation
    ) public onlyAdmin {
        Drug storage drug = drugs[_drugId]; // Get the drug by its ID
        drug.location = _newLocation; // Update the drug's location
    }

    // Function to get the details of a specific drug by its ID
    function getDrugDetails(
        uint _drugId
    )
        public
        view
        returns (string memory, uint, Status, string memory, uint, address)
    {
        Drug storage drug = drugs[_drugId]; // Get the drug by its ID
        // Return all the details of the drug
        return (
            drug.name,
            drug.quantity,
            drug.status,
            drug.location,
            drug.expirationDate,
            drug.owner
        );
    }

    // Function to get the inventory of a specific owner
    function getOwnerInventory(
        address _owner
    ) public view returns (uint, string memory) {
        Inventory storage inventory = owners[_owner]; // Get the owner's inventory details
        // Return the owner's drug count and location
        return (inventory.count, inventory.location);
    }

    // Function to check if a drug has expired based on its expiration date
    function checkExpiration(uint _drugId) public view returns (bool) {
        Drug storage drug = drugs[_drugId]; // Get the drug by its ID
        // Return true if the current time (block.timestamp) is greater than the drug's expiration date
        return block.timestamp > drug.expirationDate;
    }

    // Function to get the number of drugs available in a specific location
    function getDrugCountByLocation(
        string memory _location
    ) public view returns (uint) {
        uint count = 0; // Initialize the count to 0
        for (uint i = 1; i <= drugCount; i++) {
            // Loop through all the drugs
            // Check if the location of the drug matches the input location
            if (
                keccak256(abi.encodePacked(drugs[i].location)) ==
                keccak256(abi.encodePacked(_location))
            ) {
                count += drugs[i].quantity; // Add the drug's quantity to the count
            }
        }
        return count; // Return the total count of drugs in the location
    }

    // Function to get the number of drugs available in a specific status (e.g., Pending, Shipped, etc.)
    function getDrugCountByStatus(Status _status) public view returns (uint) {
        uint count = 0; // Initialize the count to 0
        for (uint i = 1; i <= drugCount; i++) {
            // Loop through all the drugs
            // Check if the status of the drug matches the input status
            if (drugs[i].status == _status) {
                count += drugs[i].quantity; // Add the drug's quantity to the count
            }
        }
        return count; // Return the total count of drugs in the given status
    }

    // Event to notify when a drug's ownership or location has been updated
    event DrugTransferred(
        uint drugId,
        address from,
        address to,
        uint quantity,
        string newLocation
    );
}
