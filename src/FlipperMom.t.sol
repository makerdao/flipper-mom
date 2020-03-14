pragma solidity ^0.5.15;

import "ds-test/test.sol";

import "./FlipperMom.sol";

contract FlipperMomTest is DSTest {
    FlipperMom mom;

    function setUp() public {
        mom = new FlipperMom();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
