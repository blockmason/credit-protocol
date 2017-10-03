pragma solidity ^0.4.11;

contract FoundationData {

  address foundationContract;
  bytes32 admin; //the master id associated with the admin

  struct FoundationId {
    bool initialized;
    address[] ownedAddresses;
    address pendingOwned; //an address requiring confirmation to add to owned
    uint activeUntil; //the date/time when this id deactivates
    uint depositBalanceWei; //how much deposit this owner has
    bytes32 name;
    mapping ( address => bool ) activeAddr;
  }

  mapping ( address => bytes32 ) pendings;
  mapping ( address => bytes32 )  addrToName;
  mapping ( bytes32  => FoundationId ) nameToId;

  /*
     @notice modifier to allow only the main Foundation contract to proxy calls
  */

  modifier isFoundation() {
    if(msg.sender != foundationContract) revert();
    _;
  }

  modifier isAdmin() {
    if ( compare(getAddrToName(msg.sender), admin) != 0 ) revert();
    _;
  }

  function FoundationData(bytes32 _admin) {
    admin = _admin;
    addrToName[msg.sender] = _admin;
    nameToId[_admin].initialized = true;
    nameToId[_admin].activeUntil = now + 365*24*60*60*1000; //1000 years
    nameToId[_admin].name = _admin;
    nameToId[_admin].depositBalanceWei = 0;
    nameToId[_admin].ownedAddresses.push(msg.sender);
    nameToId[_admin].activeAddr[msg.sender] = true;
  }

  function getAdmin() constant returns (bytes32) {
    return admin;
  }

  function setFoundationContract(address fc) public isAdmin {
    foundationContract = fc;
  }

  function getFoundationContract() constant returns (address) {
    return foundationContract;
  }

  /*  Setters  */
  function setIdInitialized(bytes32 fId, bool init) public isFoundation {
    nameToId[fId].initialized = init;
  }

  function pushIdOwnedAddresses(bytes32 fId, address _addr) public isFoundation {
    nameToId[fId].ownedAddresses.push(_addr);
  }

  function setIdPendingOwned(bytes32 fId, address _pendingAddr) public isFoundation {
    nameToId[fId].pendingOwned = _pendingAddr;
  }

  function clearIdPendingOwned(bytes32 fId) public isFoundation {
    nameToId[fId].pendingOwned = 0;
  }

  function setIdDepositBalanceWei(bytes32 fId, uint weiAmount) public isFoundation {
    nameToId[fId].depositBalanceWei = weiAmount;
  }

  function setIdActiveUntil(bytes32 fId, uint _activeUntil) public isFoundation {
    nameToId[fId].activeUntil = _activeUntil;
  }

  function setIdName(bytes32 fId, bytes32 val) public isFoundation {
    nameToId[fId].name = val;
  }

  function setIdActiveAddr(bytes32 fId, address _addr, bool val) public isFoundation {
    nameToId[fId].activeAddr[_addr] = val;
  }

  function deleteAddrAtIndex(bytes32 fId, uint index) {
    delete nameToId[fId].ownedAddresses[index];
  }

  /*   mapping setters   */
  function setPendings(bytes32 _name, address _addr) public isFoundation {
    pendings[_addr] = _name;
  }

  function setAddrToName(bytes32 _name, address _addr) public isFoundation {
    addrToName[_addr] = _name;
  }

  /*  Getters  */
  function idInitialized(bytes32 fId) constant returns (bool) {
    return nameToId[fId].initialized;
  }

  function idOwnedAddresses(bytes32 fId) constant returns (address[]) {
    return nameToId[fId].ownedAddresses;
  }

  function idPendingOwned(bytes32 fId) constant returns (address) {
    return nameToId[fId].pendingOwned;
  }

  function idDepositBalanceWei(bytes32 fId) constant returns (uint) {
    return nameToId[fId].depositBalanceWei;
  }

  function idActiveUntil(bytes32 fId) constant returns (uint timestamp) {
    return nameToId[fId].activeUntil;
  }

  function idIsActiveAddr(bytes32 fId, address _addr) constant returns (bool) {
    return nameToId[fId].activeAddr[_addr];
  }

  function getPending(address _addr) constant returns (bytes32) {
    return pendings[_addr];
  }

  function getAddrToName(address _addr) constant returns (bytes32) {
    return addrToName[_addr];
  }

  /*   ownedAddresses helpers   */
  /**
     @dev Finds the index of an address in the user's foundationId ownedAddresses
     @param fId the name of the FoundationID to search through.
     @param _addr the address to find.
  */
  function findAddr(bytes32 fId, address _addr) constant returns (uint) {
    uint foundAddrIndex;
    for (uint i = 0; i <= nameToId[fId].ownedAddresses.length; i ++) {
      if ( nameToId[fId].ownedAddresses[i] == _addr) {
         foundAddrIndex = i;
         return foundAddrIndex;
      }
    }
    revert(); //should only be called when it knows the address is present
  }

  function numOwnedAddrs(bytes32 fId) constant returns (uint) {
    return nameToId[fId].ownedAddresses.length;
  }

  function ownedAddrAtIndex(bytes32 fId, uint index) constant returns (address) {
    return nameToId[fId].ownedAddresses[index];
  }


  /*   helpers                  */
  function compare(bytes32 a, bytes32 b) private constant returns (int) {
    //    bytes memory a = bytes(_a);
    //    bytes memory b = bytes(_b);
    uint minLength = a.length;
    if (b.length < minLength) minLength = b.length;
    for (uint i = 0; i < minLength; i ++)
      if (a[i] < b[i])
        return -1;
      else if (a[i] > b[i])
        return 1;
    if (a.length < b.length)
      return -1;
    else if (a.length > b.length)
      return 1;
    else
      return 0;
  }
}
