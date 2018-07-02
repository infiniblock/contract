pragma solidity ^0.4.23;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
}

contract ERC20 {
    //function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function transfer(address dst, uint wad) public returns (bool);
    function allowance(address src, address guy) public view returns (uint);
    function approve(address guy, uint wad) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract InfiniBlockToken is ERC20, DSMath {
    string public constant name = "InfiniBlock"; //  token name
    string public constant symbol = "IBT";       //  token symbol
    uint   public constant decimals = 18;        //  token digit
    uint   public constant totalSupply = 10 * (10 ** 9) * (10 ** uint(decimals)); // 10 billions IBT

    bool stopped = false;
    address mint = 0;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) approvals;
    mapping (address => uint) lockTimestamp;

    event Sale(address indexed dst, uint wad, uint lockDays);

    modifier owner {
        require(mint == msg.sender);
        _;
    }

    modifier running {
        require (!stopped);
        _;
    }

    modifier unlocked {
        require (block.timestamp > lockTimestamp[msg.sender]);
        _;
    }

    constructor (address addrOwner) public {
        mint = addrOwner;
        balances[mint] = totalSupply;

        emit Transfer(address(0), mint, totalSupply);
    }

    function balanceOf(address guy) public view returns (uint) {
        return balances[guy];
    }

    function allowance(address src, address guy) public view returns (uint) {
        return approvals[src][guy];
    }

    function transfer(address dst, uint wad) public running unlocked returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], wad);
        balances[dst] = add(balances[dst], wad);

        emit Transfer(msg.sender, dst, wad);

        return true;
    }

    function transferFrom(address src, address dst, uint wad) public running returns (bool success) {
        approvals[src][msg.sender] = sub(approvals[src][msg.sender], wad);
        balances[src] = sub(balances[src], wad);
        balances[dst] = add(balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public running unlocked returns (bool success) {
        require(wad == 0 || approvals[msg.sender][guy] == 0);
        approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function saleAndLock(address dst, uint wad, uint lockDays) public owner running returns (bool success) {
        require (0 == balances[dst] && wad > 0);

        balances[mint] = sub(balances[mint], wad);
        balances[dst] = add(balances[dst], wad);
        lockTimestamp[dst] = add(block.timestamp, lockDays * 1 days);

        emit Sale(dst, wad, lockDays);

        return true;
    }

    function stop() public owner running {
        stopped = true;
    }

    function start() public owner {
        stopped = false;
    }

    function burn(uint wad) public {
        balances[msg.sender] = sub(balances[msg.sender], wad);
        balances[0x0] = add(balances[0x0], wad);

        emit Transfer(msg.sender, 0x0, wad);
    }
}
