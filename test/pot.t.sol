pragma solidity >=0.5.12;

import "../src/ds-test/src/test.sol";
import {Vat} from '../src/vat.sol';
import {Pot} from '../src/pot.sol';

import "truffle/Assert.sol";

interface Hevm {
    function warp(uint256) external;
}

contract DSRTest is DSTest {

    Vat vat;
    Pot pot;

    address vow;
    address self;
    address potb;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }

    function setUp() public {

        vat = new Vat();
        pot = new Pot(address(vat));
        vat.rely(address(pot));
        self = address(this);
        potb = address(pot);

        vow = address(bytes20("vow"));
        pot.file("vow", vow);

        vat.suck(self, self, rad(100 ether));
        vat.hope(address(pot));
    }
    function test_save_0d() public {
        Assert.equal(vat.dai(self), rad(100 ether), "");

        pot.join(100 ether);
        Assert.equal(wad(vat.dai(self)),   0 ether, "");
        Assert.equal(pot.pie(self),      100 ether, "");

        pot.drip();

        pot.exit(100 ether);
        Assert.equal(wad(vat.dai(self)), 100 ether, "");
    }
    function test_save_1d() public {
        pot.join(100 ether);
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        pot.drip();
        Assert.equal(pot.pie(self), 100 ether, "");
        pot.exit(100 ether);
        Assert.equal(wad(vat.dai(self)), 105 ether, "");
    }
    function test_drip_multi() public {
        pot.join(100 ether);
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        pot.drip();
        Assert.equal(wad(vat.dai(potb)),   105 ether, "");
        pot.file("dsr", uint(1000001103127689513476993127));  // 10% / day
        pot.drip();
        Assert.equal(wad(vat.sin(vow)), 15.5 ether, "");
        Assert.equal(wad(vat.dai(potb)), 115.5 ether, "");
        Assert.equal(pot.Pie(),          100   ether, "");
        Assert.equal(pot.chi() / 10 ** 9, 1.155 ether, "");
    }
    function test_drip_multi_inBlock() public {
        pot.drip();
        uint rho = pot.rho();
        Assert.equal(rho, now, "");
        rho = pot.rho();
        Assert.equal(rho, now - 1 days, "");
        pot.drip();
        rho = pot.rho();
        Assert.equal(rho, now, "");
        pot.drip();
        rho = pot.rho();
        Assert.equal(rho, now, "");
    }
    function test_save_multi() public {
        pot.join(100 ether);
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        pot.drip();
        pot.exit(50 ether);
        Assert.equal(wad(vat.dai(self)), 52.5 ether, "");
        Assert.equal(pot.Pie(),          50.0 ether, "");

        pot.file("dsr", uint(1000001103127689513476993127));  // 10% / day
        pot.drip();
        pot.exit(50 ether);
        Assert.equal(wad(vat.dai(self)), 110.25 ether, "");
        Assert.equal(pot.Pie(),            0.00 ether, "");
    }
    function test_fresh_chi() public {
        uint rho = pot.rho();
        Assert.equal(rho, now, "");
        Assert.equal(rho, now - 1 days, "");
        pot.drip();
        pot.join(100 ether);
        Assert.equal(pot.pie(self), 100 ether, "");
        pot.exit(100 ether);
        // if we exit in the same transaction we should not earn DSR
        Assert.equal(wad(vat.dai(self)), 100 ether, "");
    }
    function testFail_stale_chi() public {
        pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
        pot.drip();
        pot.join(100 ether);
    }
    function test_file() public {
        pot.drip();
        pot.file("dsr", uint(1));
    }
    function testFail_file() public {
        pot.file("dsr", uint(1));
    }
}
