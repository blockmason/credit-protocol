pragma solidity 0.4.15;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "tce-contracts/contracts/CPToken.sol";

contract Stake is Ownable {
    using SafeMath for uint256;

    struct Ucac {
        address ucacContractAddr; // settable by owner at any time
        uint256 totalStakedTokens;
        address owner; // may change depending on owner's staking level
                       // or desire to transfer ownership
        uint256 txLevel;
        uint256 lastTxTimestamp;
        bytes32 denomination; // TODO set this when UCAC is created
    }

    CPToken public token;
    uint256 public txPerTokenPerHour;
    uint256 public tokensToOwnUcac;

    mapping (bytes32 => Ucac) public ucacs; // ucacId -> Ucac struct

    // ucacId -> token owner address -> amount of tokens
    mapping (bytes32 => mapping (address => uint256)) public stakedTokensMap;

    function Stake(address _tokenContract, uint256 _txPerTokenPerHour, uint256 _tokensToOwnUcac) {
        token = CPToken(_tokenContract);
        txPerTokenPerHour = _txPerTokenPerHour;
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    function setTxPerTokenPerHour(uint256 _txPerTokenPerHour) public onlyOwner {
        txPerTokenPerHour = _txPerTokenPerHour;
    }

    function setTokensToOwnUcac(uint256 _tokensToOwnUcac) public onlyOwner {
        tokensToOwnUcac = _tokensToOwnUcac;
    }

    function executeUcacTx(bytes32 _ucacId) public {
        uint256 totalStaked = ucacs[_ucacId].totalStakedTokens;
        require(totalStaked > 0);

        uint256 currentDecay = totalStaked / 3600 * (now - ucacs[_ucacId].lastTxTimestamp);
        if (ucacs[_ucacId].txLevel < currentDecay) {
            ucacs[_ucacId].txLevel = 10 ** 18 / txPerTokenPerHour;
        } else {
            ucacs[_ucacId].txLevel = ucacs[_ucacId].txLevel - currentDecay + 10 ** 18 / txPerTokenPerHour;
        }

        // check ucac has tx capacity TODO do this check before txLevel is set
        // does this revert the above changes to txLevel?
        require(totalStaked >= ucacs[_ucacId].txLevel);
        ucacs[_ucacId].lastTxTimestamp = now;
    }

    /**
       @dev msg.sender must have approved Stake contract to transfer enough tokens
     **/
    function createAndStakeUcac(address _ucacContractAddr, bytes32 _ucacId, uint256 _tokensToStake) public {
        // check that _ucacId does not point to extant UCAC
        require(ucacs[_ucacId].totalStakedTokens == 0 && ucacs[_ucacId].owner == address(0));
        // checking that initial token staking amount is enough to own a UCAC
        require(_tokensToStake >= tokensToOwnUcac);
        stakeTokensInternal(_ucacId, msg.sender, _tokensToStake);
        ucacs[_ucacId].ucacContractAddr = _ucacContractAddr;
        ucacs[_ucacId].owner = msg.sender;
    }

    function setUcacContractAddr(bytes32 _ucacId, address newAddr) public {
        require(msg.sender == ucacs[_ucacId].owner);
        ucacs[_ucacId].ucacContractAddr = newAddr;
    }

    function setUcacOwner(bytes32 _ucacId, address newOwner) public {
        bool senderIsOwner = msg.sender == ucacs[_ucacId].owner;
        bool newOwnerStaked = stakedTokensMap[_ucacId][newOwner] >= tokensToOwnUcac;
        // existing owner unstaked, new owner is sender
        bool takeover = stakedTokensMap[_ucacId][ucacs[_ucacId].owner] < tokensToOwnUcac
                     && newOwner == msg.sender;
        require(newOwnerStaked && (senderIsOwner || takeover));
        ucacs[_ucacId].owner = newOwner;
    }

    /* Token staking functionality */

    /**
       @dev msg.sender must have approved Stake contract to transfer enough tokens
     **/
    function stakeTokens(bytes32 _ucacId, address _stakeholder, uint256 _numTokens) public {
        require(ucacs[_ucacId].owner != address(0));
        stakeTokensInternal(_ucacId, _stakeholder, _numTokens);
    }

    /**
       @notice Checks if this address is already in this name.
       @param _ucacId Id of the ucac tokens are staked to
       @param _numTokens Number of tokens the user wants to unstake
     **/
    function unstakeTokens(bytes32 _ucacId, uint256 _numTokens) public {
        // SafeMath will throw if _numTokens is greater than a sender's stakedTokens amount
        uint256 updatedStakedTokens = stakedTokensMap[_ucacId][msg.sender].sub(_numTokens);
        stakedTokensMap[_ucacId][msg.sender] = updatedStakedTokens;
        uint256 updatedNumTokens = ucacs[_ucacId].totalStakedTokens.sub(_numTokens);
        ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
        token.transfer(msg.sender, _numTokens);
    }

    // Private Functions

    function stakeTokensInternal(bytes32 _ucacId, address _stakeholder, uint256 _numTokens) private {
        require(token.allowance(_stakeholder, this) == _numTokens);
        token.transferFrom(_stakeholder, this, _numTokens);
        uint256 updatedStakedTokens = stakedTokensMap[_ucacId][_stakeholder].add(_numTokens);
        stakedTokensMap[_ucacId][_stakeholder] = updatedStakedTokens;
        uint256 updatedNumTokens =  ucacs[_ucacId].totalStakedTokens.add(_numTokens);
        ucacs[_ucacId].totalStakedTokens = updatedNumTokens;
    }
}
