pragma solidity >=0.5.12;

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

    function deny(address flip) public {
        mom.deny(flip);
    }

    function rely(address flip) public {
        mom.rely(flip);
    }
}

contract SimpleAuthority {
    address public authorized_caller;

    constructor(address authorized_caller_) public {
        authorized_caller = authorized_caller_;
    }

    function canCall(address src, address, bytes4) public view returns (bool) {
        return src == authorized_caller;
    }
}

contract Flipper {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Flipper/not-authorized");
        _;
    }
    constructor() public {
        wards[msg.sender] = 1;
    }
}

contract Cat {}

contract FlipperMomTest is DSTest {
    FlipperMom mom;
    MomCaller caller;
    SimpleAuthority authority;
    Flipper flip;
    address cat;

    function setUp() public {
        cat = address(new Cat());
        mom = new FlipperMom(cat);
        caller = new MomCaller(mom);
        authority = new SimpleAuthority(address(caller));
        mom.setAuthority(address(authority));
        flip = new Flipper();
        flip.rely(address(mom));
        flip.rely(cat);
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
        mom.setAuthority(address(0));
        assertTrue(mom.authority() == address(0));
    }

    // a contract that does not own the Mom cannot set a new authority
    function testFailSetAuthority() public {
        assertTrue(mom.owner() != address(caller));
        caller.setAuthority(address(caller));
    }

    function testDenyViaAuth() public {
        assertEq(flip.wards(cat), 1);
        caller.deny(address(flip));
        assertEq(flip.wards(cat), 0);
    }

    function testDenyViaOwner() public {
        mom.setAuthority(address(0));
        assertEq(flip.wards(cat), 1);
        mom.deny(address(flip));
        assertEq(flip.wards(cat), 0);
    }

    function testFailDenyNoAuthority() public {
        mom.setAuthority(address(0));
        assertTrue(mom.owner() != address(caller));
        caller.deny(address(flip));
        assertEq(flip.wards(cat), 0);
    }

    function testFailDenyUnauthorized() public {
        mom.setAuthority(address(new SimpleAuthority(address(this))));
        assertTrue(mom.owner() != address(caller));
        caller.deny(address(flip));
    }

    function testRelyViaAuth() public {
        flip.deny(cat);
        caller.rely(address(flip));
        assertEq(flip.wards(cat), 1);
    }

    function testRelyNotDenied() public {
        caller.rely(address(flip));
        assertEq(flip.wards(cat), 1);
    }

    function testRelyViaOwner() public {
        flip.deny(cat);
        mom.setAuthority(address(0));
        mom.rely(address(flip));
        assertEq(flip.wards(cat), 1);
    }

    function testFailRelyNoAuthority() public {
        flip.deny(cat);
        mom.setAuthority(address(0));
        assertTrue(mom.owner() != address(caller));
        caller.rely(address(flip));
    }

    function testFailRelyUnauthorized() public {
        flip.deny(cat);
        mom.setAuthority(address(new SimpleAuthority(address(this))));
        assertTrue(mom.owner() != address(caller));
        caller.rely(address(flip));
    }

    function testDenyRelyDeny() public {
        caller.deny(address(flip));
        caller.rely(address(flip));
        caller.deny(address(flip));
    }

    function testDenyDeny() public {
        caller.deny(address(flip));
        caller.deny(address(flip));
    }

    function testRelyRely() public {
        caller.deny(address(flip));
        caller.rely(address(flip));
        caller.rely(address(flip));
    }
}
