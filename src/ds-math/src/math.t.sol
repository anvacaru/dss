// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

import "../../ds-test/src/test.sol";
import "./math.sol";

contract DSMathTest is DSTest, DSMath {
    function setUp() public {}

    function testFail_add() public pure {
        add(2 ** 256 - 1, 1);
    }
    function test_add() public {
        Assert.equal(add(0, 0), 0, "");
        Assert.equal(add(0, 1), 1, "");
        Assert.equal(add(1, 1), 2, "");
    }

    function testFail_sub() public pure {
        sub(0, 1);
    }
    function test_sub() public {
        Assert.equal(sub(0, 0), 0, "");
        Assert.equal(sub(1, 1), 0, "");
        Assert.equal(sub(2, 1), 1, "");
    }

    function testFail_mul() public pure {
        mul(2 ** 254, 6);
    }

    function test_mul() public {
        Assert.equal(mul(0, 1), 0, "");
        Assert.equal(mul(1, 1), 1, "");
        Assert.equal(mul(2, 1), 2, "");
    }

    function test_min() public {
        Assert.equal(min(1, 1), 1, "");
        Assert.equal(min(1, 2), 1, "");
    }
    function test_max() public {
        Assert.equal(max(1, 1), 1, "");
        Assert.equal(max(1, 2), 2, "");
    }
    function test_imin() public {
        Assert.equal(imin(1, 1), 1, "");
        Assert.equal(imin(1, 2), 1, "");
        Assert.equal(imin(1, -2), -2, "");
    }
    function test_imax() public {
        Assert.equal(imax(1, 1), 1, "");
        Assert.equal(imax(1, 2), 2, "");
        Assert.equal(imax(1, -2), 1, "");
    }

    function testFail_wmul_overflow() public pure {
        wmul(2 ** 128, 2 ** 128);
    }
    function test_wmul_trivial() public {
        Assert.equal(wmul(2 ** 128 - 1, 1.0 ether), 2 ** 128 - 1, "");
        Assert.equal(wmul(0.0 ether, 0.0 ether), 0.0 ether, "");
        Assert.equal(wmul(0.0 ether, 1.0 ether), 0.0 ether, "");
        Assert.equal(wmul(1.0 ether, 0.0 ether), 0.0 ether, "");
        Assert.equal(wmul(1.0 ether, 1.0 ether), 1.0 ether, "");
    }
    function test_wmul_fractions() public {
        Assert.equal(wmul(1.0 ether, 0.2 ether), 0.2 ether, "");
        Assert.equal(wmul(2.0 ether, 0.2 ether), 0.4 ether, "");
    }

    function testFail_wdiv_zero() public pure {
        wdiv(1.0 ether, 0.0 ether);
    }
    function test_wdiv_trivial() public {
        Assert.equal(wdiv(0.0 ether, 1.0 ether), 0.0 ether, "");
        Assert.equal(wdiv(1.0 ether, 1.0 ether), 1.0 ether, "");
    }
    function test_wdiv_fractions() public {
        Assert.equal(wdiv(1.0 ether, 2.0 ether), 0.5 ether, "");
        Assert.equal(wdiv(2.0 ether, 2.0 ether), 1.0 ether, "");
    }

    function test_wmul_rounding() public {
        uint a = .950000000000005647 ether;
        uint b = .000000001 ether;
        uint c = .00000000095 ether;
        Assert.equal(wmul(a, b), c, "");
        Assert.equal(wmul(b, a), c, "");
    }
    function test_rmul_rounding() public {
        uint a = 1 ether;
        uint b = .95 ether * 10**9 + 5647;
        uint c = .95 ether;
        Assert.equal(rmul(a, b), c, "");
        Assert.equal(rmul(b, a), c, "");
    }
}
