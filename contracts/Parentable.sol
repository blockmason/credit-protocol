pragma solidity ^0.4.15;

import "./Adminable.sol";

contract Parentable is Adminable {
  address public parentContract;

  modifier onlyParent() {
    if ( (msg.sender != parentContract) ) revert();
    _;
  }

  function changeParent(address _parentContract) public onlyAdmin {
    parentContract = _parentContract;
  }
}
