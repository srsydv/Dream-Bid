pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

contract dreamBidFee is Ownable {
    uint16 public _dreamBiddingFee;

    event FeeSet(uint16 newFee, uint16 oldFee);

    function protocolFee() public view virtual returns (uint16) {
        return _dreamBiddingFee;
    }

    function getProtocolOwnerAddress() public view virtual returns (address) {
        return owner();
    }

    // Set Protocol Fee in percent
    function setProtocolFee(uint16 newFee) public virtual onlyOwner {
        if (newFee == _dreamBiddingFee) return;

        uint16 oldFee = _dreamBiddingFee;
        _dreamBiddingFee = newFee;
        emit FeeSet(newFee, oldFee);
    }
}
