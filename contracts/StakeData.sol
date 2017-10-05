pragma solidity ^0.4.15;

import "./Parentable.sol";
import "./CPToken.sol";
import "./SafeMath.sol";

contract StakeData is Parentable {
  using SafeMath for uint256;

  struct Ucac {
    address ucacContractAddr;
    address owner1;
    address owner2;
  }

  /** the token currently being checked by the contract for staking **/
  CPToken private currentToken;
  mapping (bytes32 => Ucac) public ucacs; //indexed by ucacId
  /**
      indexed by token contract => token owner address => amount of tokens

      indexes by token contract to make sure that switching currentToken doesn't
      lock users' tokens
  **/
  mapping (address => mapping (address => uint)) public stakedTokens; //

  function StakeData(address _tokenContract) {
    currentToken = CPToken(_tokenContract);
  }

  function setToken(address _tokenContract) public onlyAdmin {
    currentToken = CPToken(_tokenContract);
  }

  function getUcacAddr(bytes32 _ucacId) public constant returns (address) {
    return ucacs[_ucacId].ucacContractAddr;
  }

  function getOwner1(bytes32 _ucacId) public constant returns (address) {
    return ucacs[_ucacId].owner1;
  }

  function getOwner2(bytes32 _ucacId) public constant returns (address) {
    return ucacs[_ucacId].owner2;
  }

  function isOwner(bytes32 _ucacId, address _owner) public constant returns (bool) {
    return ucacs[_ucacId].owner1 == _owner || ucacs[_ucacId].owner2 == _owner;
  }

  function setUcacAddr(bytes32 _ucacId, address _ucacContractAddr) public onlyParent {
    ucacs[_ucacId].ucacContractAddr = _ucacContractAddr;
  }

  function setOwner1(bytes32 _ucacId, address _newOwner) public onlyParent {
    ucacs[_ucacId].owner1 = _newOwner;
  }

  function setOwner2(bytes32 _ucacId, address _newOwner) public onlyParent {
    ucacs[_ucacId].owner2 = _newOwner;
  }

  /* Token staking functionality */

  /**
      @dev only the parent contract can call this, but this locks the functionality in
   **/
  function stakeTokens(uint _numTokens) public onlyParent {
    /*
      1. check that this contract is approved to spend
      2. transfer the tokens to this contract
      3. update stakedTokens with the owner
     */
  }

  /**
     @notice Checks if this address is already in this name.
     @param _name The name of the ID.
     @param _addr The address to check.
   **/
  function returnTokens(address _tokenContract, uint _numTokens) public {
    require ( stakedTokens[_tokenContract][msg.sender] >= _numTokens );
    CPToken t = CPToken(_tokenContract);
    stakedTokens[_tokenContract][msg.sender].sub(_numTokens);
    t.transfer(msg.sender, _numTokens);
  }

}
