pragma solidity ^0.4.11;

import "./AbstractCPData.sol";

contract DebtReader {

  AbstractCPData acp;

  //T is for Temp
  uint debtIdT;
  bytes32 currencyT;
  int amountT;
  bytes32 descT;
  bytes32 debtorT;
  bytes32 creditorT;
  uint timestampT;
  bool isPendingT;
  bool isRejectedT;
  bool debtorConfirmedT;
  bool creditorConfirmedT;

  bytes32[] friendsT;
  uint[] debtIdsT;
  bytes32[] confirmersT;
  bytes32[] currenciesT;
  int[] amountsT;
  bytes32[] descsT;
  bytes32[] debtorsT;
  bytes32[] creditorsT;
  uint[] timestampsT;
  uint[] totalDebtsT;

  function DataReader(address dataContract) {
    acp = AbstractCPData(dataContract);
  }

}
