// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title UWattVendor
 * @notice This contracts was create to sell uWatt tokens at Blockchain Submit Latam 2023
 *         and will be paused after the event.
 * @custom:security-contact juan@unergy.io
 */

contract UWattVendor is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 constant WITHDRAWER = keccak256(abi.encode("WITHDRAWER"));

    uint256 constant SCALAR = 10 ** 18;
    uint256 public constant MAXIMUM_AMOUNT = 1000 * SCALAR;
    uint256 public constant MINIMUM_AMOUNT = 10 * SCALAR;

    uint256 public swapFactor = 808900; // 0.8089
    address public uWattOwner;

    IERC20 public ERC20_uWatt;
    IERC20 public ERC20_USDT;

    constructor(
        address uWattAddress,
        address usdtAddress,
        address newUWattOwner
    ) {
        _grantRole(WITHDRAWER, newUWattOwner);

        ERC20_uWatt = IERC20(uWattAddress);
        ERC20_USDT = IERC20(usdtAddress);
        uWattOwner = newUWattOwner;
    }

    function buy(
        uint256 uWattAmount
    ) external whenNotPaused returns (bool success) {
        if (uWattAmount < MINIMUM_AMOUNT)
            revert("UWattVendor: amount is less than minimum");

        address sender = msg.sender;
        uint256 balanceOfSender = ERC20_uWatt.balanceOf(sender);

        if (balanceOfSender + uWattAmount > MAXIMUM_AMOUNT)
            revert("UWattVendor: amount is greater than balance");

        uint256 usdtAmount = getUSDTAmount(uWattAmount);

        ERC20_USDT.safeTransferFrom(sender, address(this), usdtAmount);
        ERC20_uWatt.safeTransferFrom(uWattOwner, sender, uWattAmount);

        return true;
    }

    function withdraw() external onlyRole(WITHDRAWER) returns (bool success) {
        uint256 usdtBalance = ERC20_USDT.balanceOf(address(this));
        ERC20_USDT.safeTransfer(uWattOwner, usdtBalance);

        return true;
    }

    function getUSDTAmount(
        uint256 uWattAmount
    ) public view whenNotPaused returns (uint256) {
        return Math.mulDiv(uWattAmount, swapFactor, 10 ** 18);
    }

    function setSwapFactor(uint256 newSwapFactor) external whenNotPaused {
        swapFactor = newSwapFactor;
    }
}
