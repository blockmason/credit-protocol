pragma solidity 0.4.15;

import "blockmason-solidity-libs/contracts/Adminable.sol";
import "tce-contracts/contracts/CPToken.sol";
import "./StakeData.sol";


contract Stake is Adminable {
  using SafeMath for uint256;

  struct TxRecord {
    uint txsPastHour;
    uint lastTxTimestamp;
  }

  StakeData private stakeData;
  address public fluxContract;

  uint public tokensPerTxPerHour;
  uint public tokensToOwnUcac;
  uint8 public minUcacIdLength;
  uint public currentHourTimestamp;

  mapping (bytes32 => TxRecord) ucacTxs;

  function Stake(address _stakeDataContract, address _fluxContract) {
    stakeData = StakeData(_stakeDataContract);
    fluxContract = _fluxContract;
    tokensPerTxPerHour = 100;
    tokensToOwnUcac = 1000;
    minUcacIdLength = 8;
  }

  function setFlux(address _fluxContract) public onlyAdmin {
    fluxContract = _fluxContract;
  }

  function ucacTx(bytes32 _ucacId) public onlyFlux {
    if (now > (currentHourTimestamp + 1 hours)) {
      currentHourTimestamp = now;
      ucacTxs[_ucacId].txsPastHour = 1;
    }
    else {
      if(ucacTxs[_ucacId].lastTxTimestamp > currentHourTimestamp)
        ucacTxs[_ucacId].txsPastHour.add(1);
      else
        ucacTxs[_ucacId].txsPastHour = 1;
    }
    ucacTxs[_ucacId].lastTxTimestamp = now;
  }

  function ucacStatus(bytes32 _ucacId) constant public returns (bool hasCapacity, address _ucacContract){
    address ucacContract;
    uint256 totalStakedTokens;
    (ucacContract, totalStakedTokens) = stakeData.getAddrAndStaked(_ucacId);
    uint totalCapacity = totalStakedTokens.div(tokensPerTxPerHour);
    uint usedCapacity = (ucacTxs[_ucacId].txsPastHour).mul(tokensPerTxPerHour);
    return (totalCapacity.sub(usedCapacity) >= tokensPerTxPerHour, ucacContract);
  }

  /**
     @dev msg.sender must have approved StakeData to spend enough tokens
   **/
  function createAndStakeUcac(address _owner2, address _ucacContractAddr, bytes32 _ucacId, uint _tokensToStake) {
    require(!ucacInitialized(_ucacId));
    require(bytes32Len(_ucacId) >= minUcacIdLength);
    require(_tokensToStake >= tokensToOwnUcac);
    stakeData.setOwner1(_ucacId, msg.sender);
    stakeData.setOwner2(_ucacId, _owner2);
    stakeData.setUcacAddr(_ucacId, _ucacContractAddr);
    stakeData.stakeTokens(_ucacId, msg.sender, _tokensToStake);
  }

  function stakeTokens(bytes32 _ucacId, uint _tokensToStake) public {
    require(ucacInitialized(_ucacId));
    stakeData.stakeTokens(_ucacId, msg.sender, _tokensToStake);
  }

  function takeoverUcac(address _owner2, address _newUcacContractAddr, bytes32 _ucacId, uint _additionalTokensToStake) public {
    address currentOwner1 = stakeData.getOwner1(_ucacId);
    uint ownerStake = stakeData.stakedTokensMap(currentOwner1, _ucacId);
    uint newOwnerStake = stakeData.stakedTokensMap(msg.sender, _ucacId);
    require(ownerStake < tokensToOwnUcac);
    require(newOwnerStake.add(_additionalTokensToStake) >= tokensToOwnUcac);
    stakeData.setOwner1(_ucacId, msg.sender);
    stakeData.setOwner2(_ucacId, _owner2);
    stakeData.setUcacAddr(_ucacId, _newUcacContractAddr);

    if(_additionalTokensToStake > 0)
      stakeData.stakeTokens(_ucacId, msg.sender, _additionalTokensToStake);
  }

  function transferUcacOwnership(bytes32 _ucacId, address _newOwner1, address _newOwner2) public {
    uint newOwnerStake = stakeData.stakedTokensMap(_newOwner1, _ucacId);
    require(stakeData.isUcacOwner(_ucacId, msg.sender));
    require(newOwnerStake >= tokensToOwnUcac);
    stakeData.setOwner1(_ucacId, _newOwner1);
    stakeData.setOwner2(_ucacId, _newOwner2);
  }


  function ucacInitialized(bytes32 _ucacId) public constant returns (bool) {
    return stakeData.getUcacAddr(_ucacId) == address(0);
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
