// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {UWattVendor} from "../src/UWattVendor.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract CounterTest is Test {
    UWattVendor public uWattVendor;
    SimpleERC20 public ERC20_uWatt = new SimpleERC20();
    SimpleERC20 public ERC20_USDT = new SimpleERC20();

    address user1 = address(100);
    uint256 ERC20_INITIAL_AMOUNT = 100000 * 10 ** 18;

    function setUp() public {
        ERC20_USDT.mint(address(this), ERC20_INITIAL_AMOUNT);
        ERC20_uWatt.mint(address(this), ERC20_INITIAL_AMOUNT);

        uWattVendor = new UWattVendor(address(1), address(2), address(3));
    }

    function test_setSwapFactor(uint256 newSwapFactor) public {
        uWattVendor.setSwapFactor(newSwapFactor);

        assertEq(uWattVendor.swapFactor(), newSwapFactor);
    }

    function test_getUSDAmount(uint256 uWattAmount) public {
        uint256 usdtAmount = uWattVendor.getUSDTAmount(uWattAmount);
        console2.log("usdtAmount", usdtAmount);

        assertEq(
            usdtAmount,
            Math.mulDiv(uWattAmount, uWattVendor.swapFactor(), 10 ** 18)
        );
    }

    function test_withdraw() public {
        uint256 thisUSDTBalance = uWattVendor.ERC20_USDT().balanceOf(
            address(this)
        );

        address uWattOwner = uWattVendor.uWattOwner();
        uint256 uWattOwnerBalaceBefore = uWattVendor.ERC20_uWatt().balanceOf(
            uWattOwner
        );

        uWattVendor.withdraw();

        assertEq(
            uWattVendor.ERC20_USDT().balanceOf(address(this)),
            uWattOwnerBalaceBefore + thisUSDTBalance
        );
    }
}
