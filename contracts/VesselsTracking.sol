pragma solidity ^0.4.13;


library CompoundLib {

    struct compoundEntry {
        uint keyIndex;
        address addr;
        uint id;
    }

    struct compound {
        mapping(uint => compoundEntry) data;
        uint[] keys;
    }

    function insert(compound storage self, uint key, address addr, uint id) internal returns (bool replaced) {
      compoundEntry storage e = self.data[key];
      e.addr = addr;
      e.id = id;
      if (e.keyIndex > 0) {
          return true;
      } else {
          e.keyIndex = ++self.keys.length;
          self.keys[e.keyIndex - 1] = key;
          return false;
      }
  }

  function remove(compound storage self, uint key) internal returns (bool success) {
      compoundEntry storage e = self.data[key];
      if (e.keyIndex == 0)
          return false;

      if (e.keyIndex <= self.keys.length) {
          // Move an existing element into the vacated key slot.
          self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
          self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
          self.keys.length -= 1;
          delete self.data[key];
          return true;
      }
  }

  function destroy(compound storage self) internal  {
      for (uint i; i<self.keys.length; i++) {
        delete self.data[self.keys[i]];
      }
      delete self.keys;
      return ;
  }

  function contains(compound storage self, uint key) internal constant returns (bool exists) {
      return self.data[key].keyIndex > 0;
  }

  function size(compound storage self) internal constant returns (uint) {
      return self.keys.length;
  }

  function getAddr(compound storage self, uint key) internal constant returns (address) {
      return self.data[key].addr;
  }

  function getId(compound storage self, uint key) internal constant returns (uint) {
      return self.data[key].id;
  }

  function getKeyByIndex(compound storage self, uint idx) internal constant returns (uint) {
      return self.keys[idx];
  }

  function getAddrByIndex(compound storage self, uint idx) internal constant returns (address) {
      return self.data[self.keys[idx]].addr;
  }

  function getIdByIndex(compound storage self, uint idx) internal constant returns (uint) {
      return self.data[self.keys[idx]].id;
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

contract Token is Ownable {
    string public name;
    string public code;
    mapping (uint => address) public holders; // (id of thing => address of holder)
    uint maxId = 0;

    function transfer(uint _id, address _to) public {
        holders[_id] = _to;
    }

    function addToken(address _holder) public {
        holders[maxId] = _holder;
        maxId++;
    }

    function burnToken(uint _id) public {
        delete holders[_id];
    }
}

/*
* Contract for compound tokens
*/
contract CompoundToken is Token {

    using CompoundLib for CompoundLib.compound;
    CompoundLib.compound c;
/*
    function addSticked(address _addr, uint _id) public {
        sticked.insert(_addr, _id);
    }

    function unstick(address _addr, uint _id) public {

    }
*/
}



/*
* Abstract contract for token holder
*/
contract Holder {
    string public name;
    string public code;
}

contract Port is Holder {
    uint public lat;
    uint public lon;

}


contract VesselsTracking is Ownable {

}
