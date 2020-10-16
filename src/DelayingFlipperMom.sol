/// FlipperMom -- governance interface for the Flipper

// Copyright (C) 2019 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

interface FlipLike {
    function wards(address) external returns (uint);
    function rely(address) external;
    function deny(address) external;
}

interface AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

contract DelayingFlipperMom {
    address public owner;
    modifier onlyOwner { require(msg.sender == owner, "flipper-mom/only-owner"); _;}

    address public authority;
    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "flipper-mom/not-authorized");
        _;
    }
    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return AuthorityLike(authority).canCall(src, address(this), sig);
        }
    }

    // only this contract can be denied/relied
    address public cat;

    //  time of last deny
    uint denied;

    // how long to wait before allowing re-relying
    uint public delay;

    // math
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    constructor(address cat_) public {
        owner = msg.sender;
        cat = cat_;
    }

    event SetOwner(address oldOwner, address newOwner);
    function setOwner(address owner_) external onlyOwner {
        emit SetOwner(owner, owner_);
        owner = owner_;
    }

    event SetAuthority(address oldAuthority, address newAuthority);
    function setAuthority(address authority_) external onlyOwner {
        emit SetAuthority(authority, authority_);
        authority = authority_;
    }

    event SetDelay(uint oldDelay, uint newDelay);
    function setDelay(uint delay_) external onlyOwner {
        emit SetDelay(delay, delay_);
        delay = delay_;
    }

    event Rely(address flip, address usr);
    function rely(address flip) external auth {
        emit Rely(flip, cat);
        require(add(denied, delay) >= now, "flipper-mom/cannot-rely");
        FlipLike(flip).rely(cat);
        denied = 0;
    }

    event Deny(address flip, address usr);
    function deny(address flip) external auth {
        emit Deny(flip, cat);
        require(denied == 0, "flipper-mom/cannot-deny"); // prevent extension
        FlipLike(flip).deny(cat);
        denied = now;
    }
}
