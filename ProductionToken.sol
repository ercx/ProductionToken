pragma solidity ^0.4.13;



import "./SafeMath.sol";

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) view public returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);

    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {

    using SafeMath for uint;

    /* Actual balances of token holders */
    mapping (address => uint) public balances;

    /* approve() allowances */
    mapping (address => mapping (address => uint)) public allowed;

    /* Interface declaration */
    function isToken() pure public returns (bool) {
        return true;
    }

  /**
   *
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[_from] >= _value && allowed[_from][_to] >= _value);
    allowed[_from][_to] = allowed[_from][_to].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) view public returns (uint balance) {
    return balances[_owner];
  }
  
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public returns (bool success) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
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
This token is used for tracking of parts without tracking individual serial numbers
*/

contract ProductionToken is StandardToken, Ownable {

    // Who can produce new parts
    mapping (address => bool) public producers;

    // Orders of parts. provider - customer - count
    mapping (address => mapping (address => uint256)) public orders;

    // Shipments of parts. provider - customer - count
    mapping (address => mapping (address => uint256)) public shipments;

    // Kanban threshold
    mapping (address => uint256) public threshold;

    event Producer(address producer, bool value);
    event Create(address producer, uint256 value);
    event Order(address indexed provider, address indexed customer, uint256 value);
    event Shipment(address indexed provider, address indexed customer, uint256 value);
    event Delivery(address indexed provider, address indexed customer, uint256 value);

    modifier onlyProducer {
        require(producers[msg.sender]);
        _;
    }

    /*
    0. create() - создание деталей производителем
    1. order() - заказ запчастей заказчиком у поставщика
    2. shipment() - отправка запчастей поставщиком заказчику
    3. delivery() - получение запчастей заказчиком
    */
//    function transfer(address _to, uint _value) returns (bool) {
    // переписать, т. к. передача - это только отправка, а нужно ещё подтверждение получения от другой стороны
//    }


    function setProducer(address _addr, bool _value) public onlyOwner {
        require(_addr != address(0));
        producers[_addr] = _value;
        Producer(_addr, _value);
    }

    function create(uint256 _value) public onlyProducer {
        balances[msg.sender] = _value;
        totalSupply = totalSupply.add(_value);
        Create(msg.sender, _value);
    }

    function setThreshold(address _addr, uint256 _value) public {
        require(msg.sender == _addr);
        threshold[_addr] = _value;
    }

    function order(address _provider, uint256 _value) public returns (bool) {
        require(_value > 0);
        orders[_provider][msg.sender] = orders[_provider][msg.sender].add(_value);
        Order(_provider, msg.sender, _value);
        return true;
    }

    function shipment(address _customer, uint256 _value) public returns (bool) {
        require(_value > 0);
        shipments[msg.sender][_customer] = shipments[msg.sender][_customer].add(_value);
        orders[msg.sender][_customer] = _value < orders[msg.sender][_customer] ? orders[msg.sender][_customer].sub(_value) : 0;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Shipment(msg.sender, _customer, _value);
        return true;
    }

    function delivery(address _provider, uint256 _value) public returns (bool) {
        require(_value > 0);
        shipments[_provider][msg.sender] = shipments[_provider][msg.sender].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        Delivery(_provider, msg.sender, _value);
        return true;
    }
}