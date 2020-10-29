pragma solidity >=0.5.12;

import "../src/ds-test/src/test.sol";

import {Jug} from "../src/jug.sol";
import {Vat} from "../src/vat.sol";

import "truffle/Assert.sol";

interface Hevm {
    function warp(uint256) external;
}

interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,
        uint256 rate,
        uint256 spot,
        uint256 line,
        uint256 dust
    );
}

contract Rpow is Jug {
    constructor(address vat_) public Jug(vat_){}

    function pRpow(uint x, uint n, uint b) public pure returns(uint) {
        return rpow(x, n, b);
    }
}


contract JugTest is DSTest {
    Jug jug;
    Vat  vat;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }
    function rho(bytes32 ilk) internal view returns (uint) {
        (uint duty, uint rho_) = jug.ilks(ilk); duty;
        return rho_;
    }
    function Art(bytes32 ilk) internal view returns (uint ArtV) {
        (ArtV,,,,) = VatLike(address(vat)).ilks(ilk);
    }
    function rate(bytes32 ilk) internal view returns (uint rateV) {
        (, rateV,,,) = VatLike(address(vat)).ilks(ilk);
    }
    function line(bytes32 ilk) internal view returns (uint lineV) {
        (,,, lineV,) = VatLike(address(vat)).ilks(ilk);
    }

    address ali = address(bytes20("ali"));

    function setUp() public {
        
        vat  = new Vat();
        jug = new Jug(address(vat));
        vat.rely(address(jug));
        vat.init("i");

        draw("i", 100 ether);
    }
    function draw(bytes32 ilk, uint dai) internal {
        vat.file("Line", vat.Line() + rad(dai));
        vat.file(ilk, "line", line(ilk) + rad(dai));
        vat.file(ilk, "spot", 10 ** 27 * 10000 ether);
        address self = address(this);
        vat.slip(ilk, self,  10 ** 27 * 1 ether);
        vat.frob(ilk, self, self, self, int(1 ether), int(dai));
    }

    function test_drip_setup() public {
                Assert.equal(uint(now), 0, "");
                Assert.equal(uint(now), 1, "");
                Assert.equal(uint(now), 2, "");
        Assert.equal(Art("i"), 100 ether, "");
    }
    function test_drip_updates_rho() public {
        jug.init("i");
        Assert.equal(rho("i"), now, "");

        jug.file("i", "duty", 10 ** 27);
        jug.drip("i");
        Assert.equal(rho("i"), now, "");
                Assert.equal(rho("i"), now - 1, "");
        jug.drip("i");
        Assert.equal(rho("i"), now, "");
                jug.drip("i");
        Assert.equal(rho("i"), now, "");
    }
    function test_drip_file() public {
        jug.init("i");
        jug.file("i", "duty", 10 ** 27);
        jug.drip("i");
        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
    }
    function test_drip_0d() public {
        jug.init("i");
        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
        Assert.equal(vat.dai(ali), rad(0 ether), "");
        jug.drip("i");
        Assert.equal(vat.dai(ali), rad(0 ether), "");
    }
    function test_drip_1d() public {
        jug.init("i");
        jug.file("vow", ali);

        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
                Assert.equal(wad(vat.dai(ali)), 0 ether, "");
        jug.drip("i");
        Assert.equal(wad(vat.dai(ali)), 5 ether, "");
    }
    function test_drip_2d() public {
        jug.init("i");
        jug.file("vow", ali);
        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day

                Assert.equal(wad(vat.dai(ali)), 0 ether, "");
        jug.drip("i");
        Assert.equal(wad(vat.dai(ali)), 10.25 ether, "");
    }
    function test_drip_3d() public {
        jug.init("i");
        jug.file("vow", ali);

        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
                Assert.equal(wad(vat.dai(ali)), 0 ether, "");
        jug.drip("i");
        Assert.equal(wad(vat.dai(ali)), 15.7625 ether, "");
    }
    function test_drip_negative_3d() public {
        jug.init("i");
        jug.file("vow", ali);

        jug.file("i", "duty", 999999706969857929985428567);  // -2.5% / day
                Assert.equal(wad(vat.dai(address(this))), 100 ether, "");
        vat.move(address(this), ali, rad(100 ether));
        Assert.equal(wad(vat.dai(ali)), 100 ether, "");
        jug.drip("i");
        Assert.equal(wad(vat.dai(ali)), 92.6859375 ether, "");
    }

    function test_drip_multi() public {
        jug.init("i");
        jug.file("vow", ali);

        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
                jug.drip("i");
        Assert.equal(wad(vat.dai(ali)), 5 ether, "");
        jug.file("i", "duty", 1000001103127689513476993127);  // 10% / day
                jug.drip("i");
        Assert.equal(wad(vat.dai(ali)),  15.5 ether, "");
        Assert.equal(wad(vat.debt()),     115.5 ether, "");
        Assert.equal(rate("i") / 10 ** 9, 1.155 ether, "");
    }
    function test_drip_base() public {
        vat.init("j");
        draw("j", 100 ether);

        jug.init("i");
        jug.init("j");
        jug.file("vow", ali);

        jug.file("i", "duty", 1050000000000000000000000000);  // 5% / second
        jug.file("j", "duty", 1000000000000000000000000000);  // 0% / second
        jug.file("base",  uint(50000000000000000000000000)); // 5% / second
                jug.drip("i");
        Assert.equal(wad(vat.dai(ali)), 10 ether, "");
    }
    function test_file_duty() public {
        jug.init("i");
                jug.drip("i");
        jug.file("i", "duty", 1);
    }
    function testFail_file_duty() public {
        jug.init("i");
                jug.file("i", "duty", 1);
    }
    function test_rpow() public {
        Rpow r = new Rpow(address(vat));
        uint result = r.pRpow(uint(1000234891009084238901289093), uint(3724), uint(1e27));
        // python calc = 2.397991232255757e27 = 2397991232255757e12
        // expect 10 decimal precision
        Assert.equal(result / uint(1e17), uint(2397991232255757e12) / 1e17, "");
    }
}
