pragma solidity ^0.4.13;

import "./Adminable.sol";
import "./StakeData.sol";

contract Stake is Adminable {
  StakeData sd;

  mapping ( address => address[] ) ucacIdToUcac;

  function Stake(address _stakeDataContract) {
    sd = StakeData(_stakeDataContract);
  }

  //TODO:
  // min length for ucacIds
  // min tokens for creating ucacId

}
