pragma solidity 0.4.15;

import "blockmason-solidity-libs/contracts/Parentable.sol";
import "tce-contracts/contracts/CPToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./StakeData.sol";

contract Stake is Parentable {
  using SafeMath for uint256;

  struct TxRecord {
    uint txsLevel;
    uint lastTxTimestamp;
  }

  StakeData public stakeData;

  uint public txPerTokenPerHour;
  uint public tokensToOwnUcac;

  mapping (bytes32 => TxRecord) ucacTxs;

  event DebtIssued(bytes32 indexed ucacId);
  event Debug(uint a, uint b);

  function Stake(address _stakeDataContract) {
    stakeData = StakeData(_stakeDataContract);
    txPerTokenPerHour = 100;
    tokensToOwnUcac = 1000;
  }

  // TODO this is incomplete. the logging should include information about the
  // debt and a debt object should be created for storage in a separate
  // contract.
  function ucacTx(bytes32 _ucacId) public onlyParent {
    require(ucacInitialized(_ucacId));

    // get number of staked tokens
    uint256 totalStaked = stakeData.getTotalStakedTokens(_ucacId);

    uint256 currentDecay = totalStaked / 3600 * (now - ucacTxs[_ucacId].lastTxTimestamp);
    if (ucacTxs[_ucacId].txsLevel < currentDecay) {
        ucacTxs[_ucacId].txsLevel = 10 ** 18 / txPerTokenPerHour;
    } else {
        ucacTxs[_ucacId].txsLevel = ucacTxs[_ucacId].txsLevel - currentDecay + 10 ** 18 / txPerTokenPerHour;
    }

    require(totalStaked >= ucacTxs[_ucacId].txsLevel);
    ucacTxs[_ucacId].lastTxTimestamp = now;

    DebtIssued(_ucacId);
  }

  function ucacStatus(bytes32 _ucacId) public constant returns (uint, uint) {
    uint256 totalStakedTokens;
    totalStakedTokens = stakeData.getTotalStakedTokens(_ucacId);
    return (totalStakedTokens, ucacTxs[_ucacId].txsLevel);
  }

  /**
     @dev msg.sender must have approved StakeData to spend enough tokens
   **/
  function createAndStakeUcac(address _owner2, address _ucacContractAddr, bytes32 _ucacId, uint _tokensToStake) public {
    require(_tokensToStake >= tokensToOwnUcac);
    stakeData.setUcacAddr(_ucacId, _ucacContractAddr);
    stakeData.setOwner1(_ucacId, msg.sender);
    stakeData.setOwner2(_ucacId, _owner2);
    stakeData.stakeTokens(_ucacId, msg.sender, _tokensToStake);
  }

  function stakeTokens(bytes32 _ucacId, uint _tokensToStake) public {
    require(ucacInitialized(_ucacId));
    stakeData.stakeTokens(_ucacId, msg.sender, _tokensToStake);
  }

  function takeOverUcac(address _owner2, address _newUcacContractAddr, bytes32 _ucacId, uint _additionalTokensToStake) public {
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
    return stakeData.getUcacAddr(_ucacId) != address(0);
  }

}
