pragma solidity ^0.4.15;

import "./Adminable.sol";

contract Parentable is Adminable {
  address public parentContract;

  modifier onlyParent() {
    if ( (msg.sender != parentContract) ) revert();
    _;
  }

  function changeParent(address _parentContract) public onlyAdmin {
    require(_parentContract != address(0));
    parentContract = _parentContract;
  }
}
