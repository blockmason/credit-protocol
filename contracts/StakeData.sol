pragma solidity 0.4.15;

import "./Parentable.sol";
import "./CPToken.sol";
import "./SafeMath.sol";

contract StakeData is Parentable {
  using SafeMath for uint256;

  struct Ucac {
    address ucacContractAddr;
    uint numTokens;
    address owner1;
    address owner2;
  }

  /**
      @dev The token currently being checked by the contract for staking. Shouldn't change, but we leave an upgrade path.
  **/
  CPToken public currentToken;
  mapping (address => mapping (bytes32 => Ucac)) public ucacs; //indexed by ucacId

  /**
      @dev Indexed by token contract => token owner address => Ucac => amount of tokens
      indexes by token contract to make sure that switching currentToken doesn't
      lock users' tokens
  **/
  mapping (address => mapping (address => mapping (bytes32 => uint))) public stakedTokens;

  function StakeData(address _tokenContract) {
    currentToken = CPToken(_tokenContract);
  }

  /**
      @dev leaves an upgrade path for the token contract. Tokens are safe because stakedTokens can always be reclaimed by their current owner, even if the currentToken has to be changed.
   **/
  function getUcacAddr(address _tokenContract, bytes32 _ucacId) public constant returns (address) {
    return ucacs[_tokenContract][_ucacId].ucacContractAddr;
  }

  function getOwner1(address _tokenContract, bytes32 _ucacId) public constant returns (address) {
    return ucacs[_tokenContract][_ucacId].owner1;
  }

  function getOwner2(address _tokenContract, bytes32 _ucacId) public constant returns (address) {
    return ucacs[_tokenContract][_ucacId].owner2;
  }

  function isOwner(address _tokenContract, bytes32 _ucacId, address _owner) public constant returns (bool) {
    return ucacs[_tokenContract][_ucacId].owner1 == _owner || ucacs[_tokenContract][_ucacId].owner2 == _owner;
  }

  function setUcacAddr(address _tokenContract, bytes32 _ucacId, address _ucacContractAddr) public onlyParent {
    ucacs[_tokenContract][_ucacId].ucacContractAddr = _ucacContractAddr;
  }

  function setOwner1(address _tokenContract, bytes32 _ucacId, address _newOwner) public onlyParent {
    ucacs[_tokenContract][_ucacId].owner1 = _newOwner;
  }

  function setOwner2(address _tokenContract, bytes32 _ucacId, address _newOwner) public onlyParent {
    ucacs[_tokenContract][_ucacId].owner2 = _newOwner;
  }

  function setToken(address _tokenContract) public onlyAdmin {
    currentToken = CPToken(_tokenContract);
  }

  /* Token staking functionality */

  /**
      @dev only the parent contract can call this (to enable pausing of token staking for security reasons), but this locks in where tokens go to and how they are stored.
   **/
  function stakeTokens(bytes32 _ucacId, uint _numTokens) public onlyParent {
    require(currentToken.allowance(msg.sender, this) >= _numTokens);
    uint256 updatedStakedTokens = stakedTokens[address(currentToken)][msg.sender][_ucacId].add(_numTokens);
    stakedTokens[address(currentToken)][msg.sender][_ucacId] = updatedStakedTokens;
    uint256 updatedNumTokens =  ucacs[address(currentToken)][_ucacId].numTokens.add(_numTokens);
    ucacs[address(currentToken)][_ucacId].numTokens = updatedNumTokens;
    currentToken.transferFrom(msg.sender, this, _numTokens);
  }

  /**
     @notice Checks if this address is already in this name.
     @param _tokenContract The token contract this msg.sender owns tokens for
     @param _ucacId Id of the ucac tokens are staked to
     @param _numTokens Number of tokens the user wants to unstake
   **/
  function unstakeTokens(address _tokenContract, bytes32 _ucacId, uint _numTokens) public {
    CPToken t = CPToken(_tokenContract);
    uint256 updatedStakedTokens = stakedTokens[_tokenContract][msg.sender][_ucacId].sub(_numTokens);
    stakedTokens[_tokenContract][msg.sender][_ucacId] = updatedStakedTokens;
    uint256 updatedNumTokens = ucacs[_tokenContract][_ucacId].numTokens.sub(_numTokens);
    ucacs[_tokenContract][_ucacId].numTokens = updatedNumTokens;
    t.transfer(msg.sender, _numTokens);
  }

}
