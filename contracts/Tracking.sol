pragma solidity ^0.4.13;

contract Tracking {

	mapping (uint => address) flow;
	uint[] compoundParts;

	function setID(uint _id, address _addr) {
		flow[_id] = _addr;
	}

	function getID(uint _id) returns (address) {
		return flow[_id];
	}
}

contract Kanban {

	mapping (address => uint) flow;

	function transfer(address to, uint count) {
		flow[msg.sender] -= count;
		flow[to] += count;
	}
}

contract CompoundTracking {
	string public id;
	mapping (address => uint) public flow;
	address[] public parents;
	
	function getParent(address _addr) constant returns address[] {
		return _addr.parents[];
	}

	function getAllParents() constant returns address[][] {
		address[][] allparents;
		for (uint i = 0; i <= parents.length; i++)
			allparents.push(getParent(parents[i]));
		return allparents;
	}
}

