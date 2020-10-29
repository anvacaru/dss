pragma solidity >=0.5.12;

import "../src/ds-test/src/test.sol";

import {Vat}     from "../src/vat.sol";
import {Cat}     from "../src/cat.sol";
import {Flipper} from "../src/flip.sol";

import "truffle/Assert.sol";

interface Hevm {
    function warp(uint256) external;
}

contract Guy {
    Flipper flip;
    constructor(Flipper flip_) public {
        flip = flip_;
    }
    function hope(address usr) public {
        Vat(address(flip.vat())).hope(usr);
    }
    function tend(uint id, uint lot, uint bid) public {
        flip.tend(id, lot, bid);
    }
    function dent(uint id, uint lot, uint bid) public {
        flip.dent(id, lot, bid);
    }
    function deal(uint id) public {
        flip.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
    function try_yank(uint id)
        public returns (bool ok)
    {
        string memory sig = "yank(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
}


contract Gal {}

contract Cat_ is Cat {
    uint256 constant public RAD = 10 ** 45;
    uint256 constant public MLN = 10 **  6;

    constructor(address vat_) Cat(vat_) public {
        litter = 5 * MLN * RAD;
    }
}

contract Vat_ is Vat {
    function mint(address usr, uint wad) public {
        dai[usr] += wad;
    }
    function dai_balance(address usr) public view returns (uint) {
        return dai[usr];
    }
    bytes32 ilk;
    function set_ilk(bytes32 ilk_) public {
        ilk = ilk_;
    }
    function gem_balance(address usr) public view returns (uint) {
        return gem[ilk][usr];
    }
}

contract FlipTest is DSTest {

    Vat_    vat;
    Cat_    cat;
    Flipper flip;

    address ali;
    address bob;
    address gal;
    address usr = address(0xacab);

    uint256 constant public RAY = 10 ** 27;
    uint256 constant public RAD = 10 ** 45;
    uint256 constant public MLN = 10 **  6;

    function setUp() public {

        vat = new Vat_();
        cat = new Cat_(address(vat));

        vat.init("gems");
        vat.set_ilk("gems");

        flip = new Flipper(address(vat), address(cat), "gems");
        cat.rely(address(flip));

        ali = address(new Guy(flip));
        bob = address(new Guy(flip));
        gal = address(new Gal());

        Guy(ali).hope(address(flip));
        Guy(bob).hope(address(flip));
        vat.hope(address(flip));

        vat.slip("gems", address(this), 1000 ether);
        vat.mint(ali, 200 ether);
        vat.mint(bob, 200 ether);
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_kick() public {
        flip.kick({ lot: 100 ether
                  , tab: 50 ether
                  , usr: usr
                  , gal: gal
                  , bid: 0
                  });
    }
    function testFail_tend_empty() public {
        // can't tend on non-existent
        flip.tend(42, 0, 0);
    }
    function test_tend() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        Assert.equal(vat.dai_balance(ali),   199 ether, "");
        // gal receives payment
        Assert.equal(vat.dai_balance(gal),     1 ether, "");

        Guy(bob).tend(id, 100 ether, 2 ether);
        // bid taken from bidder
        Assert.equal(vat.dai_balance(bob), 198 ether, "");
        // prev bidder refunded
        Assert.equal(vat.dai_balance(ali), 200 ether, "");
        // gal receives excess
        Assert.equal(vat.dai_balance(gal),   2 ether, "");

        Guy(bob).deal(id);
        // bob gets the winnings
        Assert.equal(vat.gem_balance(bob), 100 ether, "");
    }
    function test_tend_later() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        Guy(ali).tend(id, 100 ether, 1 ether);
        // bid taken from bidder
        Assert.equal(vat.dai_balance(ali), 199 ether, "");
        // gal receives payment
        Assert.equal(vat.dai_balance(gal),   1 ether, "");
    }
    function test_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });
        Guy(ali).tend(id, 100 ether,  1 ether);
        Guy(bob).tend(id, 100 ether, 50 ether);

        Guy(ali).dent(id,  95 ether, 50 ether);
        // plop the gems
        Assert.equal(vat.gem_balance(address(0xacab)), 5 ether, "");
        Assert.equal(vat.dai_balance(ali),  150 ether, "");
        Assert.equal(vat.dai_balance(bob),  200 ether, "");
    }
    function test_tend_dent_same_bidder() public {
       uint id = flip.kick({ lot: 100 ether
                            , tab: 200 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        Assert.equal(vat.dai_balance(ali), 200 ether, "");
        Guy(ali).tend(id, 100 ether, 190 ether);
        Assert.equal(vat.dai_balance(ali), 10 ether, "");
        Guy(ali).tend(id, 100 ether, 200 ether);
        Assert.equal(vat.dai_balance(ali), 0, "");
        Guy(ali).dent(id, 80 ether, 200 ether);
    }
    function test_beg() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });
        Assert.isTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether), "");
        Assert.isTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether), "");
        // high bidder is subject to beg
        Assert.isTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether), "");
        Assert.isTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether), "");

        // can bid by less than beg at flip
        Assert.isTrue( Guy(ali).try_tend(id, 100 ether, 49 ether), "");
        Assert.isTrue( Guy(bob).try_tend(id, 100 ether, 50 ether), "");

        Assert.isTrue(!Guy(ali).try_dent(id, 100 ether, 50 ether), "");
        Assert.isTrue(!Guy(ali).try_dent(id,  99 ether, 50 ether), "");
        Assert.isTrue( Guy(ali).try_dent(id,  95 ether, 50 ether), "");
    }
    function test_deal() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        // only after ttl
        Guy(ali).tend(id, 100 ether, 1 ether);
        Assert.isTrue(!Guy(bob).try_deal(id), "");
        Assert.isTrue( Guy(bob).try_deal(id), "");

        uint ie = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        // or after end
        Guy(ali).tend(ie, 100 ether, 1 ether);
        Assert.isTrue(!Guy(bob).try_deal(ie), "");
        Assert.isTrue( Guy(bob).try_deal(ie), "");
    }
    function test_tick() public {
        // start an auction
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
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
    function test_no_deal_after_end() public {
        // if there are no bids and the auction ends, then it should not
        // be refundable to the creator. Rather, it ticks indefinitely.
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });
        Assert.isTrue(!Guy(ali).try_deal(id), "");
        Assert.isTrue(!Guy(ali).try_deal(id), "");
        Assert.isTrue( Guy(ali).try_tick(id), "");
        Assert.isTrue(!Guy(ali).try_deal(id), "");
    }
    function test_yank_tend() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: rad(50 ether)
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        Guy(ali).tend(id, 100 ether, 1 ether);

        // bid taken from bidder
        Assert.equal(vat.dai_balance(ali), 199 ether, "");
        Assert.equal(vat.dai_balance(gal),   1 ether, "");

        // we have some amount of litter in the box
        Assert.equal(cat.litter(), 5 * MLN * RAD, "");

        vat.mint(address(this), 1 ether);
        flip.yank(id);

        // bid is refunded to bidder from caller
        Assert.equal(vat.dai_balance(ali),            200 ether, "");
        Assert.equal(vat.dai_balance(address(this)),    0 ether, "");

        // gems go to caller
        Assert.equal(vat.gem_balance(address(this)), 1000 ether, "");

        // cat.scoop(tab) is called decrementing the litter accumulator
        Assert.equal(cat.litter(), (5 * MLN * RAD) - rad(50 ether), "");
    }
    function test_yank_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        // we have some amount of litter in the box
        Assert.equal(cat.litter(), 5 * MLN * RAD, "");

        Guy(ali).tend(id, 100 ether,  1 ether);
        Guy(bob).tend(id, 100 ether, 50 ether);
        Guy(ali).dent(id,  95 ether, 50 ether);

        // cannot yank in the dent phase
        Assert.isTrue(!Guy(ali).try_yank(id), "");

        // we have same amount of litter in the box
        Assert.equal(cat.litter(), 5 * MLN * RAD, "");
    }
}
