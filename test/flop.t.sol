pragma solidity >=0.5.12;

import {DSTest}  from "../src/ds-test/src/test.sol";
import {DSToken} from "../src/ds-token/src/token.sol";
import "../src/flop.sol";
import "../src/vat.sol";

import "truffle/Assert.sol";


interface Hevm {
    function warp(uint256) external;
}

contract Guy {
    Flopper flop;
    constructor(Flopper flop_) public {
        flop = flop_;
        Vat(address(flop.vat())).hope(address(flop));
        DSToken(address(flop.gem())).approve(address(flop));
    }
    function dent(uint id, uint lot, uint bid) public {
        flop.dent(id, lot, bid);
    }
    function deal(uint id) public {
        flop.deal(id);
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id));
    }
}

contract Gal {
    uint public Ash;
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function kick(Flopper flop, uint lot, uint bid) external returns (uint) {
        Ash += bid;
        return flop.kick(address(this), lot, bid);
    }
    function kiss(uint rad) external {
        Ash = sub(Ash, rad);
    }
    function cage(Flopper flop) external {
        flop.cage();
    }
}

contract Vatish is DSToken('') {
    uint constant ONE = 10 ** 27;
    function hope(address usr) public {
         approve(usr, uint(-1));
    }
    function dai(address usr) public view returns (uint) {
         return balanceOf[usr];
    }
}

contract FlopTest is DSTest {

    Flopper flop;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;
    address gal;

    function kiss(uint) public pure { }  // arbitrary callback

    function setUp() public {

        vat = new Vat();
        gem = new DSToken('');

        flop = new Flopper(address(vat), address(gem));

        ali = address(new Guy(flop));
        bob = address(new Guy(flop));
        gal = address(new Gal());

        flop.rely(gal);
        flop.deny(address(this));

        vat.hope(address(flop));
        vat.rely(address(flop));
        gem.approve(address(flop));

        vat.suck(address(this), address(this), 1000 ether);

        vat.move(address(this), ali, 200 ether);
        vat.move(address(this), bob, 200 ether);
    }

    function test_kick() public {
        Assert.equal(vat.dai(gal), 0, "");
        Assert.equal(gem.balanceOf(gal), 0 ether, "");
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 5000 ether);
        // no value transferred
        Assert.equal(vat.dai(gal), 0, "");
        Assert.equal(gem.balanceOf(gal), 0 ether, "");
        // auction created with appropriate values
        Assert.equal(flop.kicks(), id, "");
        (uint256 bid, uint256 lot, address guy, uint48 tic, uint48 end) = flop.bids(id);
        Assert.equal(bid, 5000 ether, "");
        Assert.equal(lot, 200 ether, "");
        Assert.isTrue(guy == gal, "");
        Assert.equal(uint256(tic), 0, "");
        Assert.equal(uint256(end), now + flop.tau(), "");
    }

    function test_dent() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);

        Guy(ali).dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        Assert.equal(vat.dai(ali), 190 ether, "");
        // gal receives payment
        Assert.equal(vat.dai(gal),  10 ether, "");
        Assert.equal(Gal(gal).Ash(), 0 ether, "");

        Guy(bob).dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        Assert.equal(vat.dai(bob), 190 ether, "");
        // prev bidder refunded
        Assert.equal(vat.dai(ali), 200 ether, "");
        // gal receives no more
        Assert.equal(vat.dai(gal), 10 ether, "");

        Assert.equal(gem.totalSupply(),  0 ether, "");
        gem.setOwner(address(flop));
        Guy(bob).deal(id);
        // gems minted on demand
        Assert.equal(gem.totalSupply(), 80 ether, "");
        // bob gets the winnings
        Assert.equal(gem.balanceOf(bob), 80 ether, "");
    }

    function test_dent_Ash_less_than_bid() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);
        Assert.equal(vat.dai(gal),  0 ether, "");

        Gal(gal).kiss(1 ether);
        Assert.equal(Gal(gal).Ash(), 9 ether, "");

        Guy(ali).dent(id, 100 ether, 10 ether);
        // bid taken from bidder
        Assert.equal(vat.dai(ali), 190 ether, "");
        // gal receives payment
        Assert.equal(vat.dai(gal),   10 ether, "");
        Assert.equal(Gal(gal).Ash(), 0 ether, "");

        Guy(bob).dent(id, 80 ether, 10 ether);
        // bid taken from bidder
        Assert.equal(vat.dai(bob), 190 ether, "");
        // prev bidder refunded
        Assert.equal(vat.dai(ali), 200 ether, "");
        // gal receives no more
        Assert.equal(vat.dai(gal), 10 ether, "");

        Assert.equal(gem.totalSupply(),  0 ether, "");
        gem.setOwner(address(flop));
        Guy(bob).deal(id);
        // gems minted on demand
        Assert.equal(gem.totalSupply(), 80 ether, "");
        // bob gets the winnings
        Assert.equal(gem.balanceOf(bob), 80 ether, "");
    }

    function test_dent_same_bidder() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 200 ether);

        Guy(ali).dent(id, 100 ether, 200 ether);
        Assert.equal(vat.dai(ali), 0, "");
        Guy(ali).dent(id, 50 ether, 200 ether);
    }

    function test_tick() public {
        // start an auction
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);
        // check no tick
        Assert.isTrue(!Guy(ali).try_tick(id), "");
        // run past the end
        // check not biddable
        Assert.isTrue(!Guy(ali).try_dent(id, 100 ether, 10 ether), "");
        Assert.isTrue( Guy(ali).try_tick(id), "");
        // check biddable
        (, uint _lot,,,) = flop.bids(id);
        // tick should increase the lot by pad (50%) and restart the auction
        Assert.equal(_lot, 300 ether, "");
        Assert.isTrue( Guy(ali).try_dent(id, 100 ether, 10 ether), "");
    }

    function test_no_deal_after_end() public {
        // if there are no bids and the auction ends, then it should not
        // be refundable to the creator. Rather, it ticks indefinitely.
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);
        Assert.isTrue(!Guy(ali).try_deal(id), "");
        Assert.isTrue(!Guy(ali).try_deal(id), "");
        Assert.isTrue( Guy(ali).try_tick(id), "");
        Assert.isTrue(!Guy(ali).try_deal(id), "");
    }

    function test_yank() public {
        // yanking the auction should refund the last bidder's dai, credit a
        // corresponding amount of sin to the caller of cage, and delete the auction.
        // in practice, gal == (caller of cage) == (vow address)
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);

        // confrim initial state expectations
        Assert.equal(vat.dai(ali), 200 ether, "");
        Assert.equal(vat.dai(bob), 200 ether, "");
        Assert.equal(vat.dai(gal), 0, "");
        Assert.equal(vat.sin(gal), 0, "");

        Guy(ali).dent(id, 100 ether, 10 ether);
        Guy(bob).dent(id, 80 ether, 10 ether);

        // confirm the proper state updates have occurred
        Assert.equal(vat.dai(ali), 200 ether, "");  // ali's dai balance is unchanged
        Assert.equal(vat.dai(bob), 190 ether, "");
        Assert.equal(vat.dai(gal),  10 ether, "");
        Assert.equal(vat.sin(address(this)), 1000 ether, "");

        Gal(gal).cage(flop);
        flop.yank(id);

        // confirm final state
        Assert.equal(vat.dai(ali), 200 ether, "");
        Assert.equal(vat.dai(bob), 200 ether, "");  // bob's bid has been refunded
        Assert.equal(vat.dai(gal),  10 ether, "");
        Assert.equal(vat.sin(gal),  10 ether, "");  // sin assigned to caller of cage(, "")
        (uint256 _bid, uint256 _lot, address _guy, uint48 _tic, uint48 _end) = flop.bids(id);
        Assert.equal(_bid, 0, "");
        Assert.equal(_lot, 0, "");
        Assert.equal(_guy, address(0), "");
        Assert.equal(uint256(_tic), 0, "");
        Assert.equal(uint256(_end), 0, "");
    }

    function test_yank_no_bids() public {
        // with no bidder to refund, yanking the auction should simply create equal
        // amounts of dai (credited to the gal) and sin (credited to the caller of cage)
        // in practice, gal == (caller of cage) == (vow address)
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 10 ether);

        // confrim initial state expectations
        Assert.equal(vat.dai(ali), 200 ether, "");
        Assert.equal(vat.dai(bob), 200 ether, "");
        Assert.equal(vat.dai(gal), 0, "");
        Assert.equal(vat.sin(gal), 0, "");

        Gal(gal).cage(flop);
        flop.yank(id);

        // confirm final state
        Assert.equal(vat.dai(ali), 200 ether, "");
        Assert.equal(vat.dai(bob), 200 ether, "");
        Assert.equal(vat.dai(gal),  10 ether, "");
        Assert.equal(vat.sin(gal),  10 ether, "");  // sin assigned to caller of cage(, "")
        (uint256 _bid, uint256 _lot, address _guy, uint48 _tic, uint48 _end) = flop.bids(id);
        Assert.equal(_bid, 0, "");
        Assert.equal(_lot, 0, "");
        Assert.equal(_guy, address(0), "");
        Assert.equal(uint256(_tic), 0, "");
        Assert.equal(uint256(_end), 0, "");
    }
}
