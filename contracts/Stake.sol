pragma solidity ^0.4.13;

import "blockmason-solidity-libs/contracts/Adminable.sol";
import "tce-contracts/contracts/CPToken.sol";
import "./StakeData.sol";


contract Stake is Adminable {
  using SafeMath for uint256;

  struct TxRecord {
    uint txsPastHour;
    uint lastTxTimestamp;
  }

  StakeData private sd;
  address public fluxContract;

  uint public tokensPerTxPerHour;
  uint public tokensToOwnUcac;
  uint8 public minUcacIdLength;
  uint public currentHourTimestamp;

  mapping (bytes32 => TxRecord) ucacTxs;

  function Stake(address _stakeDataContract, address _fluxContract) {
    sd = StakeData(_stakeDataContract);
    fluxContract = _fluxContract;
    tokensPerTxPerHour = 100;
    tokensToOwnUcac = 1000;
    minUcacIdLength = 8;
  }

  function setFlux(address _fluxContract) public onlyAdmin {
    fluxContract = _fluxContract;
  }

  function ucacTx(bytes32 _ucacId) public onlyFlux {
    if (now > (currentHourTimestamp + 1 hour)) {
      currentHourTimestamp = now;
      ucacTxs[_ucacId].txsPastHour = 1;
    }
    else {

    }
    /*
      - if no, check lastTxTimestamp. if it's after currentHourTimestamp, increment
- if not, do nothing
     */
  }

  /**
     @dev msg.sender must have approved StakeData to spend enough tokens
   **/
  function createAndStakeUcac(address _owner2, address _ucacContractAddr, bytes32 _ucacId, uint _tokensToStake) {
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

  function takeoverUcac(address _owner2, address _newUcacContractAddr, bytes32 _ucacId, uint _additionalTokensToStake) public {
    address currentOwner1 = sd.getOwner1(_ucacId);
    uint ownerStake = sd.stakedTokensMap(currentOwner1, _ucacId);
    uint newOwnerStake = sd.stakedTokensMap(msg.sender, _ucacId);
    require(ownerStake < tokensToOwnUcac);
    require(newOwnerStake.add(_additionalTokensToStake) >= tokensToOwnUcac);
    sd.setOwner1(_ucacId, msg.sender);
    sd.setOwner2(_ucacId, _owner2);
    sd.setUcacAddr(_ucacId, _newUcacContractAddr);

    if(_additionalTokensToStake > 0)
      sd.stakeTokens(_ucacId, msg.sender, _additionalTokensToStake);
  }

  function transferUcacOwnership(bytes32 _ucacId, address _newOwner1, address _newOwner2) public {
    uint newOwnerStake = sd.stakedTokensMap(_newOwner1, _ucacId);
    require(sd.isUcacOwner(_ucacId, msg.sender));
    require(newOwnerStake >= tokensToOwnUcac);
    sd.setOwner1(_ucacId, _newOwner1);
    sd.setOwner2(_ucacId, _newOwner2);
  }


  function ucacInitialized(bytes32 _ucacId) public constant returns (bool) {
    return sd.getUcacAddr(_ucacId) == address(0);
  }

  /* helpers */
  modifier onlyFlux() {
    require(msg.sender == fluxContract);
    _;
  }

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
