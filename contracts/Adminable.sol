pragma solidity ^0.4.15;

contract Adminable {
  address public admin1;
  address public admin2;

  modifier onlyAdmin() {
    if ( (admin1 != msg.sender) && (admin2 != msg.sender)) revert();
    _;
  }

  function Adminable() {
    admin1 = msg.sender;
  }

  function setAdmin1(address _newAdmin1) onlyAdmin {
    require(_newAdmin1 != address(0));
    admin1 = _newAdmin1;
  }

  function setAdmin2(address _newAdmin2) onlyAdmin {
    require(_newAdmin2 != address(0));
    admin2 = _newAdmin2;
  }
}
