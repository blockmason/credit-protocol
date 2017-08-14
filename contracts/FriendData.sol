pragma solidity ^0.4.11;

contract FriendData {
  address admin;
  address admin2;
  address fluxContract;

  /*  Friend  */
  struct Friend {
    address ucac;
    bool initialized;
    bytes32 f1Id;
    bytes32 f2Id;
    bool isPending;
    bool isMutual;
    bool f1Confirmed;
    bool f2Confirmed;
  }
  mapping ( bytes32 => bytes32[] ) friendIdList;
  mapping ( bytes32 => mapping ( bytes32 => Friend )) friendships;

  /*  modifiers  */
  modifier isAdmin() {
    if ( (admin != msg.sender) && (admin2 != msg.sender)) revert();
    _;
  }

  modifier isParent() {
    if ( (msg.sender != fluxContract) ) revert();
    _;
  }

  /* main functions */
  function FriendData(address _admin2) {
    admin = msg.sender;
    admin2 = _admin2;
  }

  function setFluxContract(address _fluxContract) public isAdmin {
    fluxContract = _fluxContract;
  }

  function getFluxContract() constant returns (address) {
    return fluxContract;
  }

  function getAdmins() constant returns (address, address) {
    return (admin, admin2);
  }

  bytes32 f;
  bytes32 s;
  /* Flux helpers */
  function friendIndices(bytes32 p1, bytes32 p2) constant returns (bytes32, bytes32) {
    if ( friendships[p1][p2].initialized )
      return (p1, p2);
    else
      return (p2, p1);
  }

  /* Friend Getters */
  function numFriends(bytes32 fId) constant returns (uint) {
    return friendIdList[fId].length;
  }
  function friendIdByIndex(bytes32 fId, uint index) constant returns (bytes32) {
    return friendIdList[fId][index];
  }

  function fUcac(bytes32 p1, bytes32 p2) constant returns (address) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].ucac;
  }
  function fInitialized(bytes32 p1, bytes32 p2) constant returns (bool) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].initialized;
  }
  function ff1Id(bytes32 p1, bytes32 p2) constant returns (bytes32) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].f1Id;
  }
  function ff2Id(bytes32 p1, bytes32 p2) constant returns (bytes32) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].f2Id;
  }
  function fIsPending(bytes32 p1, bytes32 p2) constant returns (bool) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].isPending;
  }
  function fIsMutual(bytes32 p1, bytes32 p2) constant returns (bool) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].isMutual;
  }
  function ff1Confirmed(bytes32 p1, bytes32 p2) constant returns (bool) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].f1Confirmed;
  }
  function ff2Confirmed(bytes32 p1, bytes32 p2) constant returns (bool) {
    (f, s) = friendIndices(p1, p2);
    return friendships[f][s].f2Confirmed;
  }

  /* Friend Setters */
  function pushFriendId(bytes32 myId, bytes32 friendId) public isParent {
    friendIdList[myId].push(friendId);
  }
  function setFriendIdByIndex(bytes32 myId, uint idx, bytes32 newFriendId) public isParent{
    friendIdList[myId][idx] = newFriendId;
  }

  function fSetUcac(bytes32 p1, bytes32 p2, address ucac) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].ucac = ucac;
  }
  function fSetInitialized(bytes32 p1, bytes32 p2, bool initialized) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].initialized = initialized;
  }
  function fSetf1Id(bytes32 p1, bytes32 p2, bytes32 id) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].f1Id = id;
  }
  function fSetf2Id(bytes32 p1, bytes32 p2, bytes32 id) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].f2Id = id;
  }
  function fSetIsPending(bytes32 p1, bytes32 p2, bool isPending) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].isPending = isPending;
  }
  function fSetIsMutual(bytes32 p1, bytes32 p2, bool isMutual) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].isMutual = isMutual;
  }
  function fSetf1Confirmed(bytes32 p1, bytes32 p2, bool f1Confirmed) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].f1Confirmed = f1Confirmed;
  }
  function fSetf2Confirmed(bytes32 p1, bytes32 p2, bool f2Confirmed) public isParent {
    (f, s) = friendIndices(p1, p2);
    friendships[f][s].f2Confirmed = f2Confirmed;
  }

}
