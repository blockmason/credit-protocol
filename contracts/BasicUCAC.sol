pragma solidity 0.4.15;

contract BasicUCAC {
    function allowTransaction(address creditor, address debtor, uint256 amount) public returns (bool) {
        return true;
    }
}
