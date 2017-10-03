pragma solidity ^0.4.11;

contract AbstractFoundationData {

  function getAdmin() constant returns (bytes32);
  function getFoundationContract() constant returns (address);

  /*  Setters  */
  function setIdInitialized(bytes32 fId, bool init);
  function pushIdOwnedAddresses(bytes32 fId, address _addr);
  function setIdPendingOwned(bytes32 fId, address _pendingAddr);
  function clearIdPendingOwned(bytes32 fId);
  function setIdDepositBalanceWei(bytes32 fId, uint weiAmount);
  function setIdActiveUntil(bytes32 fId, uint _activeUntil);
  function setIdName(bytes32 fId, bytes32 val);
  function setIdActiveAddr(bytes32 fId, address _addr, bool val);

  function deleteAddrAtIndex(bytes32 fId, uint index);

  /*   mapping setters  */
  function setPendings(bytes32 _name, address _addr);
  function setAddrToName(bytes32 _name, address _addr);

  /*  Getters  */
  function idInitialized(bytes32 fId) constant returns (bool);
  function idOwnedAddresses(bytes32 fId) constant returns (address[]);
  function idPendingOwned(bytes32 fId) constant returns (address);
  function idDepositBalanceWei(bytes32 fId) constant returns (uint);
  function idActiveUntil(bytes32 fId) constant returns (uint timestamp);
  function idIsActiveAddr(bytes32 fId, address _addr) constant returns (bool);

  function getPending(address _addr) constant returns (bytes32);
  function getAddrToName(address _addr) constant returns (bytes32);

  function findAddr(bytes32 fId, address _addr) constant returns (uint);
  function numOwnedAddrs(bytes32 fId) constant returns (uint);
  function ownedAddrAtIndex(bytes32 fId, uint index) constant returns (address);
}
