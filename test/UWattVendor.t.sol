// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {UWattVendor} from "../src/UWattVendor.sol";
import {SimpleERC20} from "../src/SimpleERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract UWattVendorTest is Test {
    UWattVendor public uWattVendor;
    SimpleERC20 public ERC20_uWatt = new SimpleERC20();
    SimpleERC20 public ERC20_USDT = new SimpleERC20();

    address user1 = address(100);
    address uWattOwner;

    uint256 ERC20_INITIAL_AMOUNT = 100000 * 10 ** 18;

    function setUp() public {
        uWattVendor = new UWattVendor(
            address(ERC20_uWatt),
            address(ERC20_USDT),
            address(1)
        );

        uWattOwner = uWattVendor.uWattOwner();

        ERC20_USDT.mint(address(user1), ERC20_INITIAL_AMOUNT);
        ERC20_uWatt.mint(address(uWattOwner), ERC20_INITIAL_AMOUNT);

        vm.prank(uWattOwner);
        ERC20_uWatt.approve(address(uWattVendor), type(uint256).max);
    }

    function test_setSwapFactor(uint256 newSwapFactor) public {
        uWattVendor.setSwapFactor(newSwapFactor);

        assertEq(uWattVendor.swapFactor(), newSwapFactor);
    }

    function test_getUSDAmount(uint256 uWattAmount) public {
        uint256 usdtAmount = uWattVendor.getUSDTAmount(uWattAmount);

        assertEq(
            usdtAmount,
            Math.mulDiv(uWattAmount, uWattVendor.swapFactor(), 10 ** 18)
        );
    }

    function test_buyLessThanMinumun() public {
        uint256 uWattAmount = uWattVendor.MINIMUM_AMOUNT() - 1;

        uint256 usdtAmount = uWattVendor.getUSDTAmount(uWattAmount);

        vm.startPrank(user1);
        ERC20_USDT.approve(address(uWattVendor), usdtAmount);

        vm.expectRevert("UWattVendor: amount is less than minimum");
        uWattVendor.buy(uWattAmount);
        vm.stopPrank();
    }

    function test_buyMoreThanMaximun() public {
        uint256 uWattAmount = uWattVendor.MAXIMUM_AMOUNT() + 1;

        uint256 usdtAmount = uWattVendor.getUSDTAmount(uWattAmount);

        vm.startPrank(user1);
        ERC20_USDT.approve(address(uWattVendor), usdtAmount);

        vm.expectRevert("UWattVendor: amount is greater than balance");
        uWattVendor.buy(uWattAmount);
        vm.stopPrank();
    }

    function test_buy() public {
        uint256 uWattAmount = uWattVendor.MINIMUM_AMOUNT() * 4;
        uint256 usdtAmount = uWattVendor.getUSDTAmount(uWattAmount);

        vm.startPrank(user1);
        ERC20_USDT.approve(address(uWattVendor), usdtAmount);

        bool success = uWattVendor.buy(uWattAmount);
        if (!success) revert();
        vm.stopPrank();

        assertEq(ERC20_USDT.balanceOf(address(uWattVendor)), usdtAmount);
    }

    function test_withdraw() public {
        uint256 uWattAmount = uWattVendor.MINIMUM_AMOUNT() * 4;
        uint256 usdtAmount = uWattVendor.getUSDTAmount(uWattAmount);

        vm.startPrank(user1);
        ERC20_USDT.approve(address(uWattVendor), usdtAmount);

        uWattVendor.buy(uWattAmount);
        vm.stopPrank();

        vm.prank(uWattOwner);
        bool success = uWattVendor.withdraw();
        if (!success) revert();

        assertEq(ERC20_USDT.balanceOf(address(uWattOwner)), usdtAmount);
    }
}
