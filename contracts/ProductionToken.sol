pragma solidity ^0.4.15;

import "./SafeMath.sol";

/*
* Simple token contract, ERC20-style, but without possibility of transfer tokens
*
*/
contract SimpleToken {
    using SafeMath for uint;

    uint public totalSupply;

    /* Actual balances of token holders */
    mapping (address => uint) public balances;

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of. 
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) view public returns (uint balance) {
        return balances[_owner];
    }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner = msg.sender;

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


/*
This token contract is used for tracking of parts without tracking individual serial numbers
*/

contract SimpleProductionToken is SimpleToken, Ownable {

    // Who can produce new parts
    mapping (address => bool) public producers;

    // Orders of parts. provider - customer - count
    mapping (address => mapping (address => uint256)) public orders;

    // Shipments of parts. provider - customer - count
    mapping (address => mapping (address => uint256)) public shipments;

    // Kanban thresholds
    struct kanbanStruct {
        address provider;
        uint256 threshold;
        uint256 autoOrderValue;
    }

    mapping (address => kanbanStruct) public thresholds;

    event Producer(address producer, bool value);
    event AutoOrderSet(address provider, address customer, uint256 threshold, uint256 autoOrderValue);
    event Create(address producer, uint256 value);
    event Order(address indexed provider, address indexed customer, uint256 value);
    event Shipment(address indexed provider, address indexed customer, uint256 value);
    event Acception(address indexed provider, address indexed customer, uint256 value);
    event Burn(address indexed provider, uint256 value);

    // Only procucer can create new parts
    modifier onlyProducer {
        require(producers[msg.sender]);
        _;
    }

    function SimpleProductionToken() public {
        setProducer(msg.sender, true);
    }

    function isProductionToken() pure public returns (bool) {
        return true;
    }

    function setProducer(address _addr, bool _value) public onlyOwner {
        require(_addr != address(0));
        producers[_addr] = _value;
        Producer(_addr, _value);
    }

    function create(uint256 _value) internal onlyProducer {
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        Create(msg.sender, _value);
    }

    function setAutoOrder(address _provider, uint256 _threshold, uint256 _autoOrderValue) public {
        require(_provider != address(0) && _threshold > 0 && _autoOrderValue > 0);
        thresholds[msg.sender].provider = _provider;
        thresholds[msg.sender].threshold = _threshold;
        thresholds[msg.sender].autoOrderValue = _autoOrderValue;
        AutoOrderSet(_provider, msg.sender, _threshold, _autoOrderValue);
        checkThreshold(msg.sender);
    }

    function checkThreshold(address _customer) public {
        if (thresholds[_customer].threshold > 0) {
            uint256 remaining = balances[_customer].add(orders[thresholds[_customer].provider][_customer]).add(shipments[thresholds[_customer].provider][_customer]);
            if (remaining <= thresholds[_customer].threshold) {
                orders[thresholds[_customer].provider][_customer] = orders[thresholds[_customer].provider][_customer].add(thresholds[_customer].autoOrderValue);
                Order(thresholds[_customer].provider, _customer, thresholds[_customer].autoOrderValue);
            }
        }
    }

    function order(address _provider, uint256 _value) public returns (bool) {
        require(_value > 0);
        orders[_provider][msg.sender] = orders[_provider][msg.sender].add(_value);
        Order(_provider, msg.sender, _value);
        return true;
    }

    function ship(address _customer, uint256 _value) internal returns (bool) {
        require(_value >= balances[msg.sender]);
        shipments[msg.sender][_customer] = shipments[msg.sender][_customer].add(_value);
        orders[msg.sender][_customer] = _value < orders[msg.sender][_customer] ? orders[msg.sender][_customer].sub(_value) : 0;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Shipment(msg.sender, _customer, _value);
        return true;
    }

    function accept(address _provider, uint256 _value) internal returns (bool) {
        require(_value >= shipments[_provider][msg.sender]);
        shipments[_provider][msg.sender] = shipments[_provider][msg.sender].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Acception(_provider, msg.sender, _value);
        return true;
    }

    function burn(uint256 _value) internal {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }

// TODO
//    function cancelOrder()

}


/*
* This token contract is used for tracking of parts with individual serial numbers
*/

contract ProductionToken is SimpleProductionToken {

    struct partsStruct {
        address holder;
        string metadata;
    }

    mapping (uint256 => partsStruct) public parts;
    mapping (uint256 => address) public partShipments;

    uint256 public lastId;

    modifier onlyHolder(uint256 _partId) {
        require(msg.sender == parts[_partId].holder);
        _;
    }

    function createPart(string _metadata) onlyProducer public {
        super.create(1);
        lastId++;
        parts[lastId].holder = msg.sender;
        parts[lastId].metadata = _metadata;
    }

    function getPartHolder(uint256 _partId) view public returns (address) {
        return parts[_partId].holder;
    }

    function shipPart(uint256 _partId, address _customer) onlyHolder(_partId) public {
        super.ship(_customer, 1);
        partShipments[_partId] = _customer;
    }

    function acceptPart(uint256 _partId) public {
        require(partShipments[_partId] == msg.sender);
        super.accept(getPartHolder(_partId), 1);
        parts[_partId].holder = msg.sender;
        delete partShipments[_partId];
    }

    function burnPart(uint256 _partId) onlyHolder(_partId) public {
        super.burn(1);
        delete parts[_partId];
    }

}

