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
    event CancelOrder(address indexed provider, address indexed customer, uint256 value);
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

    function cancelOrder(address _provider, uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= orders[_provider][msg.sender]);
        orders[_provider][msg.sender] = orders[_provider][msg.sender].sub(_value);
        CancelOrder(_provider, msg.sender, _value);
        return true;
    }

    function ship(address _customer, uint256 _value) internal returns (bool) {
        require(_value <= balances[msg.sender]);
        shipments[msg.sender][_customer] = shipments[msg.sender][_customer].add(_value);
        orders[msg.sender][_customer] = _value < orders[msg.sender][_customer] ? orders[msg.sender][_customer].sub(_value) : 0;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Shipment(msg.sender, _customer, _value);
        return true;
    }

    function accept(address _provider, uint256 _value) internal returns (bool) {
        require(_value > 0);
        require(_value <= shipments[_provider][msg.sender]);
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

    struct stickStruct {
        address masterToken;              // foreign master token address
        uint256 masterPartId;      // foreign master part id
    }

    mapping (uint256 => partsStruct) public parts;
    mapping (uint256 => address) public partShipments;

    uint256 public lastId;

    // Foreign parts sticked to the part of this token
    // (this part id => struct)
    mapping (uint256 => stickStruct) public sticked;
    /*
    // (foreign token address => foreign partId => this token partId)
    mapping (address => mapping (uint256 => uint256)) public reverseSticked;

    // Foreign master token of sticked part of this token
    // (partId => token address)
    mapping (uint256 => address) public masterToken;
    */

    event StickPart(address holder, uint256 partId, address addr, uint256 masterPartId);
    event UnstickPart(address holder, uint256 partId);

    modifier onlyHolder(uint256 _partId) {
        require(msg.sender == parts[_partId].holder);
        _;
    }

    modifier notSticked(uint256 _partId) {
        require(sticked[_partId].masterToken == address(0));
        require(sticked[_partId].masterPartId == 0);
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

    function shipPart(uint256 _partId, address _customer) onlyHolder(_partId) notSticked(_partId) public {
        super.ship(_customer, 1);
        partShipments[_partId] = _customer;
    }

    function acceptPart(uint256 _partId) notSticked(_partId) public {
        require(partShipments[_partId] == msg.sender);
        super.accept(getPartHolder(_partId), 1);
        parts[_partId].holder = msg.sender;
        delete partShipments[_partId];
    }

    function burnPart(uint256 _partId) onlyHolder(_partId) notSticked(_partId) public {
        super.burn(1);
        delete parts[_partId];
    }

    function stickPart(uint256 _partId, address _addr, uint256 _masterPartId) onlyHolder(_partId) notSticked(_partId) public {
        require(_addr != address(0));
        require(_partId != 0);
        require(_masterPartId != 0);
        ProductionToken masterToken;
        masterToken = ProductionToken(sticked[_partId].masterToken);
        require(masterToken.isProductionToken());
        require(msg.sender == masterToken.getPartHolder(_masterPartId));
        sticked[_partId].masterToken = _addr;
        sticked[_partId].masterPartId = _masterPartId;
        StickPart(msg.sender, _partId, _addr, _masterPartId);
    }

    function unstickPart(uint256 _partId) onlyHolder(_partId) public {
        require(_partId != 0);
        ProductionToken masterToken;
        masterToken = ProductionToken(sticked[_partId].masterToken);
        require(masterToken.isProductionToken());
        address holder = masterToken.getPartHolder(sticked[_partId].masterPartId);
        parts[_partId].holder = holder;
        balances[holder] = balances[holder].add(1);
        balances[msg.sender] = balances[msg.sender].sub(1);
        delete sticked[_partId];
        UnstickPart(msg.sender, _partId);
    }

    function isSticked(uint256 _partId) view public returns (bool) {
        if (sticked[_partId].masterToken == address(0))
            return false;
        else
            return true;
    }

}

