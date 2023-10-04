// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract UWattVendor is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 constant WITHDRAWER = keccak256(abi.encode("WITHDRAWER"));

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

    function sell(uint256 uWattAmount) external returns (bool success) {
        address sender = msg.sender;
        uint256 usdtAmount = getUSDTAmount(uWattAmount);

        ERC20_uWatt.safeTransferFrom(sender, address(this), usdtAmount);
        ERC20_USDT.safeTransferFrom(uWattOwner, sender, uWattAmount);

        return true;
    }

    function withdraw() external onlyRole(WITHDRAWER) returns (bool success) {
        uint256 usdtBalance = ERC20_USDT.balanceOf(address(this));
        ERC20_uWatt.safeTransfer(msg.sender, usdtBalance);

        return true;
    }

    function getUSDTAmount(uint256 uWattAmount) public view returns (uint256) {
        return Math.mulDiv(uWattAmount, swapFactor, 10 ** 18);
    }

    function setSwapFactor(uint256 newSwapFactor) external {
        swapFactor = newSwapFactor;
    }
}
