// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

error UWattVendor_AMOUNT_IS_LESS_THAN_MINIMUM();
error UWattVendor_CANNOT_BUY_MORE_UWATTS();
error UWattVendor_NO_MORE_UWATTS_TO_SELL();
error UWattVendor_INVALID_VALUE();

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
    uint256 public MAXIMUM_AMOUNT = 1000 * SCALAR;
    uint256 public MINIMUM_AMOUNT = 10 * SCALAR;

    uint256 public MAX_UWATTS_TO_SELL = 10000 * SCALAR;
    uint256 public UWATTS_SOLD = 0;

    uint256 public swapFactor = 904048; // 0.904048 USDT per uWatt
    address public uWattOwner;

    IERC20 public ERC20_uWatt;
    IERC20 public ERC20_USDT;

    event UWattVendor_UWATTS_PURCHASED(
        address indexed sender,
        uint256 indexed uWattAmount,
        uint256 indexed usdtAmount
    );
    event UWattVendor_UWATTS_WITHDRAWN(
        address indexed sender,
        uint256 indexed uWattAmount
    );
    event UWattVendor_SWAP_FACTOR_UPDATED(
        address indexed sender,
        uint256 indexed newSwapFactor
    );
    event UWattVendor_MAX_UWATTS_TO_SELL_UPDATED(
        address indexed sender,
        uint256 indexed newMaxUWattsToSell
    );
    event UWattVendor_MAXIMUM_AMOUNT_UPDATED(
        address indexed sender,
        uint256 indexed newMaximumAmount
    );
    event UWattVendor_MINIMUM_AMOUNT_UPDATED(
        address indexed sender,
        uint256 indexed newMinimumAmount
    );

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
            revert UWattVendor_AMOUNT_IS_LESS_THAN_MINIMUM();

        if (UWATTS_SOLD + uWattAmount > MAX_UWATTS_TO_SELL)
            revert UWattVendor_NO_MORE_UWATTS_TO_SELL();

        address sender = msg.sender;
        uint256 balanceOfSender = ERC20_uWatt.balanceOf(sender);

        if (balanceOfSender + uWattAmount > MAXIMUM_AMOUNT)
            revert UWattVendor_CANNOT_BUY_MORE_UWATTS();

        uint256 usdtAmount = getUSDTAmount(uWattAmount);

        UWATTS_SOLD += uWattAmount;

        ERC20_USDT.safeTransferFrom(sender, address(this), usdtAmount);
        ERC20_uWatt.safeTransferFrom(uWattOwner, sender, uWattAmount);

        emit UWattVendor_UWATTS_PURCHASED(sender, uWattAmount, usdtAmount);

        return true;
    }

    function withdraw() external onlyRole(WITHDRAWER) returns (bool success) {
        uint256 usdtBalance = ERC20_USDT.balanceOf(address(this));
        ERC20_USDT.safeTransfer(uWattOwner, usdtBalance);

        emit UWattVendor_UWATTS_WITHDRAWN(uWattOwner, usdtBalance);

        return true;
    }

    function getUSDTAmount(
        uint256 uWattAmount
    ) public view whenNotPaused returns (uint256) {
        return Math.mulDiv(uWattAmount, swapFactor, SCALAR);
    }

    function setSwapFactor(
        uint256 newSwapFactor
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        swapFactor = newSwapFactor;

        emit UWattVendor_SWAP_FACTOR_UPDATED(msg.sender, newSwapFactor);
    }

    function setMaxUWattsToSell(
        uint256 newMaxUWattsToSell
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (newMaxUWattsToSell < UWATTS_SOLD)
            revert UWattVendor_INVALID_VALUE();

        MAX_UWATTS_TO_SELL = newMaxUWattsToSell;

        emit UWattVendor_MAX_UWATTS_TO_SELL_UPDATED(
            msg.sender,
            newMaxUWattsToSell
        );
    }

    function setMaximunAmount(
        uint256 newMaximumAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        MAXIMUM_AMOUNT = newMaximumAmount;

        emit UWattVendor_MAX_UWATTS_TO_SELL_UPDATED(
            msg.sender,
            newMaximumAmount
        );
    }

    function setMinimunAmount(
        uint256 newMinimumAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        MINIMUM_AMOUNT = newMinimumAmount;

        emit UWattVendor_MINIMUM_AMOUNT_UPDATED(msg.sender, newMinimumAmount);
    }
}
