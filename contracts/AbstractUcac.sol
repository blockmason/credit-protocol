pragma solidity ^0.4.11;

contract AbstractUcac {
  function newDebt(address _sender, bytes32 debtorId, bytes32 creditorId, bytes32 currencyCode, int amount, bytes32 desc) constant returns (bool allowed, address capacityProvider);
  function confirmDebt(address _sender, bytes32 myId, bytes32 friendId, uint debtId) constant returns (bool allowed, address capacityProvider);
  function rejectDebt(address _sender, bytes32 myId, bytes32 friendId, uint debtId) constant returns (bool allowed, address capacityProvider);
  function addFriend(address _sender, bytes32 myId, bytes32 friendId) constant returns (bool allowed, address capacityProvider);
  function deleteFriend(address _sender, bytes32 myId, bytes32 friendId) constant returns (bool allowed, address capacityProvider);
}
