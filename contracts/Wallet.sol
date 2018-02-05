pragma solidity ^0.4.15;

import "./SafeMath.sol";
import "./EIP20.sol";

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

contract StickableToken is EIP20 {

    mapping (address => mapping (address => uint256)) stickedBalances;
    address masterAddress;

    modifier notSticked() {
        require (masterAddress == address(0));
        _;
    }

    function transfer(address _to, uint256 _value) public notSticked returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public notSticked returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function stick(address _stickedToken, uint256 _value) public notSticked {

    }

}

*/

contract Wallet is Ownable {

//    enum tokenTypes {pro, e20, e721}
//    mapping (address => tokenTypes) tokens;

//	ProductionToken proToken;
//    ERC20 erc20Token;// = new ERC20(0xB04cfa8a26D602fb50232CEe0DaF29060264e04B); // monaco
//    ERC721 erc721Token;

//    address who = 0x9E87d8C8603b2ceB27E7b6bb8be46488F8e90Da1; // Sergey's

    struct recipeStruct {
        address tokenC;
        uint256 valueA;
        uint256 valueB;
        uint256 valueC;
        address holder;
    }

    uint256 public mergeIndex;

    mapping (address => mapping (address => recipeStruct)) public recipeAB; // tokenA - tokenB

    function getTokenBalance(address _tokenAddr, address _holderAddr) public view returns (uint256) {
        EIP20 eip20Token;
        eip20Token = EIP20(_tokenAddr);
        return eip20Token.balanceOf(_holderAddr);
    }

    function getTokenDecimals(address _tokenAddr) public view returns (uint8) {
        EIP20 eip20Token;
        eip20Token = EIP20(_tokenAddr);
        return eip20Token.decimals();
    }

    function setRecipe(address _tokenA, address _tokenB, address _tokenC, uint256 _valueA, uint256 _valueB, uint256 _valueC, address _holderAddr) public {
        recipeAB[_tokenA][_tokenB] = recipeStruct(_tokenC, _valueA, _valueB, _valueC, _holderAddr);
    }

    function merge(address _tokenA, address _tokenB) public {
        if (recipeAB[_tokenA][_tokenB].tokenC != address(0)) {
            EIP20 tokenA;
            tokenA = EIP20(_tokenA);
            EIP20 tokenB;
            tokenB = EIP20(_tokenB);
            EIP20 tokenC;
            tokenC = EIP20(recipeAB[_tokenA][_tokenB].tokenC);
            tokenA.transferFrom(msg.sender, this, recipeAB[_tokenA][_tokenB].valueA);
            tokenB.transferFrom(msg.sender, this, recipeAB[_tokenA][_tokenB].valueB);
            tokenC.transfer(msg.sender, recipeAB[_tokenA][_tokenB].valueC);
        }
    }
    
    function transferTokens(address _tokenAddr, address _to, uint256 _value) public onlyOwner {
        EIP20 token;
        token = EIP20(_tokenAddr);
        if (token.balanceOf(this) > 0)
            token.transfer(_to, _value);
    }
    
}

