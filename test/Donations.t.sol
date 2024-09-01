// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

interface Donations {
    function donated(address user) external view returns (uint256);
}

contract DonationsTest is Test {
    mapping(address donator => uint256 value) mDonations;
    Donations public donations;

    function setUp() public {
        donations = Donations(HuffDeployer.config().deploy("Donations"));
    }

    function mapLocation(
        uint256 slot,
        uint256 key
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(key, slot)));
    }

    function testDonationsSimple() external {
        mDonations[address(this)] = 100;

        uint256 donated = 10;
        bytes32 key = 0;
        uint256 donator = uint256(uint160(address(this)));
        uint256 mappingSlot;
        assembly {
            mstore(0x00, donator)
            mappingSlot := mDonations.slot
            mstore(0x20, mappingSlot)
            key := keccak256(0, 0x40)
            donated := sload(key)
        }
        assertEq(donated, 100, "Wrong donated balance");

        assertEq(donations.donated(address(1)), 0);
        vm.deal(address(this), 100000);
        (bool success, ) = address(donations).call{value: 10}("");
        assert(success);

        assertEq(donations.donated(address(this)), 10);
        (success, ) = address(donations).call{value: 30}("");
        assert(success);
        assertEq(donations.donated(address(this)), 40);

        vm.deal(address(1), 30);
        vm.prank(address(1));
        (success, ) = address(donations).call{value: 30}("");
        assert(success);
        assertEq(donations.donated(address(1)), 30);
    }

    function testDonations(uint256[] memory amounts) public {
        uint256 sum;
        for (uint256 i; i < amounts.length; ) {
            vm.deal(address(this), amounts[i]);
            sum += amounts[i];
            (bool success, ) = address(donations).call{value: amounts[i]}("");
            require(success, "call failed");
            assertEq(
                donations.donated(address(this)),
                sum,
                "Wrong expected donated balance"
            );
            unchecked {
                if (amounts.length == ++i || sum + amounts[i] < sum) break;
            }
        }
    }
}
