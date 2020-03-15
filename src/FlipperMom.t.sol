pragma solidity ^0.5.15;

import "ds-test/test.sol";

import "./FlipperMom.sol";

contract MomCaller {
    FlipperMom mom;

    constructor(FlipperMom mom_) public {
        mom = mom_;
    }

    function setOwner(address newOwner) public {
        mom.setOwner(newOwner);
    }

    function setAuthority(address newAuthority) public {
        mom.setAuthority(newAuthority);
    }
}

contract FlipperMomTest is DSTest {
    FlipperMom mom;
    MomCaller caller;

    function setUp() public {
        mom = new FlipperMom();
        caller = new MomCaller(mom);
    }

    function testSetOwner() public {
        assertTrue(mom.owner() == address(this));
        assertTrue(mom.owner() != address(0));
        mom.setOwner(address(0));
        assertTrue(mom.owner() == address(0));
    }

    // a contract that does not own the Mom cannot set a new owner
    function testFailSetOwner() public {
        assertTrue(mom.owner() != address(caller));
        caller.setOwner(address(0));
    }

    function testSetAuthority() public {
        assertTrue(mom.owner() == address(this));
        assertTrue(mom.authority() != address(caller));
        mom.setAuthority(address(caller));
        assertTrue(mom.authority() == address(caller));
    }

    // a contract that does not own the Mom cannot set a new authority
    function testFailSetAuthority() public {
        assertTrue(mom.owner() != address(caller));
        caller.setAuthority(address(caller));
    }
}
