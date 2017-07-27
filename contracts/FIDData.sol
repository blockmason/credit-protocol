pragma solidity ^0.4.11;

contract FIDData {
  address admin;
  address admin2;
  address debtContract;
  address friendContract;

  /*  Friend  */
  struct Friend {
    bool initialized;
    bytes32 f1Id;
    bytes32 f2Id;
    bool isPending;
    bool isMutual;
    bool f1Confirmed;
    bool f2Confirmed;
  }
  mapping ( bytes32 => bytes32[] ) friendIdList;
  mapping ( bytes32 => mapping ( bytes32 => Friendship )) friendships;

  /*  Debt  */
  mapping ( bytes32 => bool ) currencyCodes;
  uint nextDebtId;

  struct Debt {
    uint id;
    uint timestamp;
    int amount;
    bytes32 currencyCode;
    bytes32 debtorId;
    bytes32 creditorId;
    bool isPending;
    bool isRejected;
    bool debtorConfirmed;
    bool creditorConfirmed;
    bytes32 desc;
  }

  //only goes one way-- debts[X][Y] means there's no debts [Y][Z]
  mapping ( bytes32 => mapping ( bytes32 => Debt[] )) debts;

  //global variables to be used in functions
  bytes32 first; //these two order indices in the debts mapping
  bytes32 second;

  modifier isAdmin() {
    if ( (admin != msg.sender) && (admin2 != msg.sender)) revert();
    _;
  }

  modifier isParent() {
    if ( (msg.sender != debtContract) && (msg.sender != friendContract)) revert();
    _;
  }

  function FIDData(address _admin2) {
    admin = msg.sender;
    admin2 = _admin2;
  }

  function setDebtContract(address _debtContract) public isAdmin {
    debtContract = _debtContract;
  }
  function setFriendContract(address _friendContract) public isAdmin {
    friendContract = _friendContract;
  }


}
