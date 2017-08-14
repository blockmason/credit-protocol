pragma solidity ^0.4.11;

import "./AbstractFoundation.sol";
import "./AbstractDebtData.sol";
import "./AbstractFriendReader.sol";

//check conditions on all these
contract Fid {
  bytes32 admin;
  address idUcac; //used to identify this ucac's data in data contracts

  AbstractFoundation af;
  AbstractDebtData add;
  AbstractFriendReader afr;
  mapping (bytes32 => bool) currencies;

  function Fid(bytes32 _admin, address foundationContract, address debtDataContract, address friendReaderContract) {
    af  = AbstractFoundation(foundationContract);
    add = AbstractDebtData(debtDataContract);
    afr = AbstractFriendReader(friendReaderContract);
    admin = _admin;
    currencies["USD"] = true;
  }

  function getIdUcac() constant returns (address) {
    return idUcac;
  }

  function setIdUcac(address _idUcac) public isAdmin {
    idUcac = _idUcac;
  }

  function addCurrency(bytes32 _code) public isAdmin {
    currencies[_code] = true;
  }

  function newDebt(address _sender, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) constant isInitialized returns (bool allowed, address capacityProvider, address ucacId) {
    bytes32 name = af.resolveToName(_sender);
    if ( !ownsOneId(name, debtorId, creditorId) )
      return (false, 0, idUcac);
    if ( !areFriends(debtorId, creditorId) )
      return (false, 0, idUcac);
    if ( !currencyValid(currencyCode) )
      return (false, 0, idUcac);
    return (true, 0, idUcac);
  }

  function confirmDebt(address _sender, bytes32 myId, bytes32 friendId, uint debtId) constant isInitialized returns (bool allowed, address capacityProvider, address ucacId) {
    if ( !isIdOwner(_sender, myId) )
      return (false, 0, idUcac);
    return (true, 0, idUcac);
  }

  function rejectDebt(address _sender, bytes32 myId, bytes32 friendId, uint debtId) constant isInitialized returns (bool allowed, address capacityProvider, address ucacId) {
    if ( !isIdOwner(_sender, myId) )
      return (false, 0, idUcac);
    return (true, 0, idUcac);
  }

  function addFriend(address _sender, bytes32 myId, bytes32 friendId) constant isInitialized returns (bool allowed, address capacityProvider, address ucacId) {
    if ( !isIdOwner(_sender, myId) )
      return (false, 0, idUcac);
    return (true, 0, idUcac);
  }

  function deleteFriend(address _sender, bytes32 myId, bytes32 friendId) constant isInitialized returns (bool allowed, address capacityProvider, address ucacId) {
    if ( !isIdOwner(_sender, myId) )
      return (false, 0, idUcac);
    if ( !allBalancesZero(myId, friendId) )
      return (false, 0, idUcac);
    return (true, 0, idUcac);
  }

  //helpers
  function isMember(bytes32 s, bytes32[] l) constant returns(bool) {
    for ( uint i=0; i < l.length; i++ ) {
      if ( af.idEq(l[i], s)) return true;
    }
    return false;
  }

  //modifiers
  modifier isAdmin() {
    require(af.idEq(admin, af.resolveToName(msg.sender)));
    _;
  }

  modifier isInitialized() {
    require ( idUcac != 0 );
    _;
  }

  function isIdOwner(address _caller, bytes32 _name) constant returns (bool) {
    return af.isUnified(_caller, _name);
  }

  function ownsOneId(bytes32 _id, bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return af.idEq(_id, _id1) || af.idEq(_id, _id2);
  }

  function currencyValid(bytes32 _currencyCode) constant returns (bool) {
    return currencies[_currencyCode];
  }

  function areFriends(bytes32 _id1, bytes32 _id2) constant returns (bool) {
    return afr.areFriends(idUcac, _id1, _id2);
  }

  mapping ( bytes32 => int ) balByCurrency;
  bytes32[] currenciesTemp;
  function allBalancesZero(bytes32 p1, bytes32 p2) constant isInitialized returns (bool) {
    currenciesTemp.length = 0;
    for ( uint i = 0; i < add.numDebts(idUcac, p1, p2); i++ ) {
      bytes32 c = add.dCurrencyCode(idUcac, p1, p2, i);
      if ( ! isMember(c, currenciesTemp) ) {
        balByCurrency[c] = 0;
        currenciesTemp.push(c);
      }
      balByCurrency[c] += add.dAmount(idUcac, p1, p2, i);
    }
    //throw error if all balances aren't 0
    for ( uint j=0; j < currenciesTemp.length; j++ )
      if ( balByCurrency[currenciesTemp[j]] != 0 )
        return false;
    return true;
  }

}
