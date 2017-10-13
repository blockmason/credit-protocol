pragma solidity 0.4.15;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "blockmason-solidity-libs/contracts/Parentable.sol";
import "tce-contracts/contracts/CPToken.sol";

contract Stake is Parentable {
    using SafeMath for uint256;

    struct Ucac {
        address ucacContractAddr;
        uint256 totalStakedTokens;
        address owner1;
        address owner2;
        uint256 txsLevel;
        uint256 lastTxTimestamp;
    }

    CPToken public token;
    // admin should be able to update these
    uint public txPerTokenPerHour;
    uint public tokensToOwnUcac;

    mapping (bytes32 => Ucac) public ucacs; // indexed by ucacId
    /**
        @dev Indexed by token owner address => Ucac => amount of tokens
        // TODO perhaps switch the order of this ucac -> id -> int?
    **/
    mapping (address => mapping (bytes32 => uint)) public stakedTokensMap;

    function Stake(address _tokenContract) {
        token = CPToken(_tokenContract);
        txPerTokenPerHour = 100;
        tokensToOwnUcac = 1000 * 10 ** 18;
    }

    // TODO this is incomplete. the logging should include information about the
    // debt and a debt object should be created for storage in a separate
    // contract.
    function ucacTx(bytes32 _ucacId) public onlyParent {
      require(ucacInitialized(_ucacId));
      // get number of staked tokens
      uint256 totalStaked = ucacs[_ucacId].totalStakedTokens;

      uint256 currentDecay = totalStaked / 3600 * (now - ucacs[_ucacId].lastTxTimestamp);
      if (ucacs[_ucacId].txsLevel < currentDecay) {
          ucacs[_ucacId].txsLevel = 10 ** 18 / txPerTokenPerHour;
      } else {
          ucacs[_ucacId].txsLevel = ucacs[_ucacId].txsLevel - currentDecay + 10 ** 18 / txPerTokenPerHour;
      }

      require(totalStaked >= ucacs[_ucacId].txsLevel);
      ucacs[_ucacId].lastTxTimestamp = now;

    }

    // TODO is this necessary, just get the ucac...
    // TODO this should refresh the txlevel perhaps, but then it could not be constant
    function ucacStatus(bytes32 _ucacId) public constant returns (uint, uint) {
      uint256 totalStakedTokens = ucacs[_ucacId].totalStakedTokens;
      return (totalStakedTokens, ucacs[_ucacId].txsLevel);
    }

    /**
       @dev msg.sender must have approved StakeData to spend enough tokens
     **/
    function createAndStakeUcac(address _owner2, address _ucacContractAddr, bytes32 _ucacId, uint _tokensToStake) public {
      require(_tokensToStake >= tokensToOwnUcac);
      stakeTokens(_ucacId, msg.sender, _tokensToStake);
      ucacs[_ucacId].ucacContractAddr = _ucacContractAddr;
      ucacs[_ucacId].owner1 = msg.sender;
      ucacs[_ucacId].owner2 = _owner2;
    }

    function stakeTokens(bytes32 _ucacId, uint _tokensToStake) public {
      require(ucacInitialized(_ucacId));
      stakeTokens(_ucacId, msg.sender, _tokensToStake);
    }

    function ucacInitialized(bytes32 _ucacId) public constant returns (bool) {
      return ucacs[_ucacId].ucacContractAddr != address(0);
    }

    /* Token staking functionality */

    /**
        @dev only the parent contract can call this (to enable pausing of token staking for security reasons), but this locks in where tokens go to and how they are stored.
     **/
    function stakeTokens(bytes32 _ucacId, address _stakeholder, uint _numTokens) public onlyParent {
      require(token.allowance(_stakeholder, this) >= _numTokens);
      uint256 updatedStakedTokens = stakedTokensMap[_stakeholder][_ucacId].add(_numTokens);
      stakedTokensMap[_stakeholder][_ucacId] = updatedStakedTokens;
      uint256 updatedNumTokens =  ucacs[_ucacId].totalStakedTokens.add(_numTokens);
      ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
      token.transferFrom(_stakeholder, this, _numTokens);
    }

    /**
       @notice Checks if this address is already in this name.
       @param _ucacId Id of the ucac tokens are staked to
       @param _numTokens Number of tokens the user wants to unstake
     **/
    function unstakeTokens(bytes32 _ucacId, uint _numTokens) public {
      // SafeMath will throw if _numTokens is greater than a sender's stakedTokens amount
      uint256 updatedStakedTokens = stakedTokensMap[msg.sender][_ucacId].sub(_numTokens);
      stakedTokensMap[msg.sender][_ucacId] = updatedStakedTokens;
      uint256 updatedNumTokens = ucacs[_ucacId].totalStakedTokens.sub(_numTokens);
      ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
      token.transfer(msg.sender, _numTokens);
    }

    // TODO why checking the stake of only owner 1? Is this a useful function?
    // function takeOverUcac(address _owner2, address _newUcacContractAddr, bytes32 _ucacId, uint _additionalTokensToStake) public {
    //   address currentOwner1 = stakeData.getOwner1(_ucacId);
    //   uint ownerStake = stakeData.stakedTokensMap(currentOwner1, _ucacId);
    //   uint newOwnerStake = stakeData.stakedTokensMap(msg.sender, _ucacId);
    //   require(ownerStake < tokensToOwnUcac);
    //   require(newOwnerStake.add(_additionalTokensToStake) >= tokensToOwnUcac);
    //   stakeData.setOwner1(_ucacId, msg.sender);
    //   stakeData.setOwner2(_ucacId, _owner2);
    //   stakeData.setUcacAddr(_ucacId, _newUcacContractAddr);

    //   if(_additionalTokensToStake > 0)
    //     stakeData.stakeTokens(_ucacId, msg.sender, _additionalTokensToStake);
    // }

    // TODO setting owner should simply require that the owner have a certain amount of tokens staked, no point in having this separate function
    // function transferUcacOwnership(bytes32 _ucacId, address _newOwner1, address _newOwner2) public {
    //   uint newOwnerStake = stakeData.stakedTokensMap(_newOwner1, _ucacId);
    //   require(stakeData.isUcacOwner(_ucacId, msg.sender));
    //   require(newOwnerStake >= tokensToOwnUcac);
    //   stakeData.setOwner1(_ucacId, _newOwner1);
    //   stakeData.setOwner2(_ucacId, _newOwner2);
    // }
}
