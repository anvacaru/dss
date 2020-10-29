pragma solidity >=0.5.12;

import "../src/ds-test/src/test.sol";
import {DSToken} from "../lib/ds-token/src/token.sol";
import "../src/flap.sol";
import "../src/vat.sol";

import "truffle/Assert.sol";


interface Hevm {
    function warp(uint256) external;
}

contract Guy {
    Flapper flap;
    constructor(Flapper flap_) public {
        flap = flap_;
        Vat(address(flap.vat())).hope(address(flap));
        DSToken(address(flap.gem())).approve(address(flap));
    }
    function tend(uint id, uint lot, uint bid) public {
        flap.tend(id, lot, bid);
    }
    function deal(uint id) public {
        flap.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id));
    }
}

contract FlapTest is DSTest {

    Flapper flap;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;

    function setUp() public {

        vat = new Vat();
        gem = new DSToken('');

        flap = new Flapper(address(vat), address(gem));

        ali = address(new Guy(flap));
        bob = address(new Guy(flap));

        vat.hope(address(flap));
        gem.approve(address(flap));

        vat.suck(address(this), address(this), 1000 ether);

        gem.mint(1000 ether);
        gem.setOwner(address(flap));

        gem.push(ali, 200 ether);
        gem.push(bob, 200 ether);
    }
    function test_kick() public {
        Assert.equal(vat.dai(address(this)), 1000 ether, "");
        Assert.equal(vat.dai(address(flap)),    0 ether, "");
        flap.kick({ lot: 100 ether
                  , bid: 0
                  });
        Assert.equal(vat.dai(address(this)),  900 ether, "");
        Assert.equal(vat.dai(address(flap)),  100 ether, "");
    }
    function test_tend() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        // lot taken from creator
        Assert.equal(vat.dai(address(this)), 900 ether, "");

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        Assert.equal(gem.balanceOf(ali), 199 ether, "");
        // payment remains in auction
        Assert.equal(gem.balanceOf(address(flap)),  1 ether, "");

        Guy(bob).tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        Assert.equal(gem.balanceOf(bob), 198 ether, "");
        // prev bidder refunded
        Assert.equal(gem.balanceOf(ali), 200 ether, "");
        // excess remains in auction
        Assert.equal(gem.balanceOf(address(flap)),   2 ether, "");

        Guy(bob).deal(id);
        // high bidder gets the lot
        Assert.equal(vat.dai(address(flap)),  0 ether, "");
        Assert.equal(vat.dai(bob), 100 ether, "");
        // income is burned
        Assert.equal(gem.balanceOf(address(flap)),   0 ether, "");
    }
    function test_tend_same_bidder() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        Guy(ali).tend(id, 100 ether, 190 ether);
        Assert.equal(gem.balanceOf(ali), 10 ether, "");
        Guy(ali).tend(id, 100 ether, 200 ether);
        Assert.equal(gem.balanceOf(ali), 0, "");
    }
    function test_beg() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        Assert.isTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether), "");
        Assert.isTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether), "");
        // high bidder is subject to beg
        Assert.isTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether), "");
        Assert.isTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether), "");
    }
    function test_tick() public {
        // start an auction
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        // check no tick
        Assert.isTrue(!Guy(ali).try_tick(id), "");
        // run past the end
        // check not biddable
        Assert.isTrue(!Guy(ali).try_tend(id, 100 ether, 1 ether), "");
        Assert.isTrue( Guy(ali).try_tick(id), "");
        // check biddable
        Assert.isTrue( Guy(ali).try_tend(id, 100 ether, 1 ether), "");
    }
}
