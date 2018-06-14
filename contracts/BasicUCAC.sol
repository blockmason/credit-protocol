pragma solidity ^0.4.24;

contract BasicUCAC {
    function allowTransaction(address, address, uint256) public returns (bool) {
        return true;
    }
}
