pragma solidity ^0.4.13;

import "./Adminable.sol";
import "./StakeData.sol";
import "tce-contracts/contracts/CPToken.sol";

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

  /**
     @dev msg.sender must have approved StakeData to spend enough tokens
   **/
  function createAndStakeUcac(address _owner2, address _ucacContractAddr, bytes32 _ucacId, uint _tokensToStake) {
    address owner1 = sd.getOwner1(_ucacId);
    require(!ucacInitialized(_ucacId));
    require(bytes32Len(_ucacId) >= minUcacIdLength);
    require(_tokensToStake >= tokensToOwnUcac);
    sd.setOwner1(_ucacId, msg.sender);
    sd.setOwner2(_ucacId, _owner2);
    sd.setUcacAddr(_ucacId, _ucacContractAddr);
    sd.stakeTokens(_ucacId, msg.sender, _tokensToStake);
  }

  function stakeTokens(bytes32 _ucacId, uint _tokensToStake) public {
    require(ucacInitialized(_ucacId));
    sd.stakeTokens(_ucacId, msg.sender, _tokensToStake);
  }

  function takeoverUcac(address _owner2, address _newUcacContractAddr, bytes32 _ucacId, uint _tokensToStake) public {
  address currentOwner1 = sd.getOwner1(_ucacId);
  uint ownerStake = sd.stakedTokensMap(address(sd.currentToken), currentOwner1, _ucacId);
    /*
      - add owner2 and msg.sender as owners
      - change contract address
     */
  }

  function transferUcacOwnership(bytes32 _ucacId, address _newOwner1, address _newOwner2) public {
    uint ownerStake = sd.stakedTokensMap(address(sd.currentToken), _newOwner1, _ucacId);
    require(sd.isUcacOwner(address(sd.currentToken), _ucacId, msg.sender));
    require(ownerStake >= tokensToOwnUcac);
    sd.setOwner1(_ucacId, _newOwner1);
    sd.setOwner2(_ucacId, _newOwner2);
  }


  function ucacInitialized(bytes32 _ucacId) public constant returns (bool) {
    return sd.getUcacAddr(_ucacId) == address(0);
  }

  /* helpers */
  function bytes32Len(bytes32 b) private returns (uint8 length) {
    uint8 tmpLen = 0;
    for (uint8 i=0; i < 32; i++) {
      if(b[i] == 0) break;
      else tmpLen += 1;
    }
      return tmpLen;
  }

  //NOTES:
  // min length for ucacIds
  // name staking/ucac ownership
  /*
    if owner1 doesn't have the right number of tokens staked, someone else can take over the contract
   */

}
