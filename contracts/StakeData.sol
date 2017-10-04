pragma solidity ^0.4.15;

import "./Parentable.sol";
import "./CPToken.sol";

contract StakeData is Parentable {

  struct Ucac {
    address ucacContractAddr;
    address owner1;
    address owner2;
  }

  CPToken private token;
  mapping (bytes32 => Ucac) public ucacs; //indexed by ucacId
  mapping (address => uint) public stakedTokens; //indexed by token owner address

  function StakeData(address _tokenContract) {
    token = CPToken(_tokenContract);
  }

  function setToken(address _tokenContract) public onlyAdmin {
    token = CPToken(_tokenContract);
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
     @dev
     has no modifiers--people can always get their tokens back
   **/
  function returnTokens(uint _numTokens) public {
    /*
      1. check that msg.sender owns enough
      2. check that our balance of tokens is high enough (duplicate check??)
      3. transfer ownership to msg.sender
     */
  }

}
