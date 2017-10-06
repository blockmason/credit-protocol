pragma solidity 0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";
import "tce-contracts/contracts/CPToken.sol";

contract StakeData is Parentable {
  using SafeMath for uint256;

  struct Ucac {
    address ucacContractAddr;
    uint totalStakedTokens;
    address owner1;
    address owner2;
  }

  CPToken public token;
  mapping (bytes32 => Ucac) public ucacs; //indexed by ucacId

  /**
      @dev Indexed by token owner address => Ucac => amount of tokens
  **/
  mapping (address => mapping (bytes32 => uint)) public stakedTokensMap;

  function StakeData(address _tokenContract) {
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

  function getTotalStakedTokens(bytes32 _ucacId) public constant returns (uint256) {
    return ucacs[_ucacId].totalStakedTokens;
  }

  function isUcacOwner(bytes32 _ucacId, address _owner) public constant returns (bool) {
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
      @dev only the parent contract can call this (to enable pausing of token staking for security reasons), but this locks in where tokens go to and how they are stored.
   **/
  function stakeTokens(bytes32 _ucacId, address _stakeholder, uint _numTokens) public onlyParent {
    require(token.allowance(_stakeholder, this) >= _numTokens);
    uint256 updatedStakedTokens = stakedTokensMap[_stakeholder][_ucacId].add(_numTokens);
    stakedTokensMap[_stakeholder][_ucacId] = updatedStakedTokens;
    uint256 updatedNumTokens =  ucacs[_ucacId].totalStakedTokens.add(_numTokens);
    ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
    token.transferFrom(_stakeholder, this, _numTokens);
  }

  /**
     @notice Checks if this address is already in this name.
     @param _ucacId Id of the ucac tokens are staked to
     @param _numTokens Number of tokens the user wants to unstake
   **/
  function unstakeTokens(bytes32 _ucacId, uint _numTokens) public {
    uint256 updatedStakedTokens = stakedTokensMap[msg.sender][_ucacId].sub(_numTokens);
    stakedTokensMap[msg.sender][_ucacId] = updatedStakedTokens;
    uint256 updatedNumTokens = ucacs[_ucacId].totalStakedTokens.sub(_numTokens);
    ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
    token.transfer(msg.sender, _numTokens);
  }

}
