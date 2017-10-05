pragma solidity ^0.4.13;

import "./Adminable.sol";
import "./StakeData.sol";

contract Stake is Adminable {

  struct TxRecord {
    uint txsPastHour;
    uint lastTxTimestamp;
  }

  StakeData private sd;

  uint public tokensPerTxPerHour;
  uint public tokensToOwnUcac;
  uint8 public minUcacIdLength;
  uint public currentHourTimestamp;

  mapping (bytes32 => TxRecord) ucacTxs;

  function Stake(address _stakeDataContract) {
    sd = StakeData(_stakeDataContract);
    tokensPerTxPerHour = 100;
    tokensToOwnUcac = 1000;
    minUcacIdLength = 8;
  }

  function ucacTx(bytes32 ucacId) public {
    /*
      - ucacContractAddr must match msg.sender
      - check whether currentHourTimestamp + 1 hour > now
      - if yes, do the tx and reset txsPastHour to 0
      - if no, check lastTxTimestamp. if it's after currentHourTimestamp, increment
- if not, do nothing
     */
  }

  function createUcac(bytes32 ucacId) {
    /*
      - check that the ucac has correct name length
      - check that it has no current owner1 with sufficient stake
     */
  }

  function stakeTokens(bytes32 _ucacId, uint _numTokens) public {
    /*
      - can only stake to initialized ucacs
      - get currentToken from StakeData and pass it as the token address
      - pass msg.sender as the stakeHolder
     */
  }

  //NOTES:
  // min length for ucacIds
  // name staking/ucac ownership
  /*
    if owner1 doesn't have the right number of tokens staked, someone else can take over the contract
   */

}
