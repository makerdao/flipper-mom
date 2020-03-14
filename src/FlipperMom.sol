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

pragma solidity 0.5.15;

contract FlipLike {
    function rely(address) external;
    function deny(address) external;
}

contract AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) public view returns (bool);
}

contract FlipperMom {
    address public owner;
    modifier onlyOwner { require(msg.sender == owner, "flipper-mom/only-owner"); _;}

    address public authority;
    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "osm-mom/not-authorized");
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

    constructor() public {
        owner = msg.sender;
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

    // Should this remain delayed to guard against malicious governance?
    event Rely(address flip, address usr);
    function rely(address flip, address usr) external auth {
        emit Rely(flip, usr);
        FlipLike(flip).rely(usr);
    }

    event Deny(address flip, address usr);
    function deny(address flip, address usr) external auth {
        emit Deny(flip, usr);
        FlipLike(flip).deny(usr);
    }
}
