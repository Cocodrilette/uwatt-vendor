// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {UWattVendor} from "../src/UWattVendor.sol";
import {ERC20UWATT} from "../src/ERC20UWATT.sol";
import {ERC20USDT} from "../src/ERC20USDT.sol";

contract UWattVendorScript is Script {
    function run() public {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPK);

        address uWattAddress;
        address usdtAddress;
        address newUWattOwner;

        if (block.chainid == 137) {
            uWattAddress = 0xdD875635231E68E846cE190b1396AC0295D9e577;
            usdtAddress = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
            newUWattOwner = 0xa846cb52cc481dd6E223b1Cd2AbD49f17120AddE;
        } else {
            ERC20UWATT ERC20_uWatt = new ERC20UWATT();
            ERC20USDT ERC20_USDT = new ERC20USDT();
            uWattAddress = address(ERC20_uWatt);
            usdtAddress = address(ERC20_USDT);
            newUWattOwner = 0x3Bd208F4bC181439b0a6aF00C414110b5F9d2656;

            ERC20_uWatt.mint(address(newUWattOwner), 100000 * 10 ** 18);
        }

        new UWattVendor(uWattAddress, usdtAddress, newUWattOwner);

        vm.stopBroadcast();
    }
}
