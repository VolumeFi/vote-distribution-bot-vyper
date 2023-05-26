# @version 0.3.7

struct Deposit:
    path: DynArray[address, MAX_SIZE]
    amount1: uint256
    depositor: address
    deposit_time: uint256
    duration: uint256

interface WrappedEth:
    def deposit(): payable

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view

interface VeSDT:
    def create_lock(_value: uint256, _unlock_time: uint256): nonpayable

interface UniswapV2Router:
    def WETH() -> address: pure
    def swapExactTokensForTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256) -> DynArray[uint256, MAX_SIZE]: nonpayable

event Deposited:
    deposit_id: uint256
    token0: address
    amount0: uint256
    amount1: uint256
    depositor: address
    unlock_time: uint256

SDT: constant(address) = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F
veSDT: constant(address) = 0x0C30476f66034E11782938DF8e4384970B6c9e8a
MAX_SIZE: constant(uint256) = 8
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
WETH: immutable(address)
ROUTER: immutable(address)
deposit_size: public(uint256)
deposits: public(HashMap[uint256, Deposit])
deposits_user: public(HashMap[address, uint256])
compass: public(address)

event UpdateCompass:
    old_compass: address
    new_compass: address

@external
def __init__(_compass: address, router: address):
    self.compass = _compass
    ROUTER = router
    WETH = UniswapV2Router(ROUTER).WETH()
    log UpdateCompass(empty(address), _compass)

@internal
def _safe_approve(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("approve(address,uint256)")),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed approve

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_from, _to, _value, method_id=method_id("transferFrom(address,address,uint256)")),
        max_outsize=32
    )  # dev: failed transferFrom
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transferFrom

@external
@payable
def deposit(path: DynArray[address, MAX_SIZE], amount0: uint256, min_amount1: uint256, duration: uint256):
    assert len(path) > 2, "Wrong path"
    _path: DynArray[address, MAX_SIZE] = path
    token0: address = path[0]
    last_index: uint256 = unsafe_sub(len(path), 1)
    assert path[last_index] == SDT, "Wrong path"
    if token0 == VETH:
        assert msg.value == amount0
        if msg.value > amount0:
            send(msg.sender, msg.value - amount0)
        WrappedEth(WETH).deposit(value=amount0)
        _path[0] = WETH
    else:
        orig_balance: uint256 = ERC20(token0).balanceOf(self)
        self._safe_transfer_from(token0, msg.sender, self, amount0)
        assert ERC20(token0).balanceOf(self) == orig_balance + amount0
    amounts: DynArray[uint256, MAX_SIZE] = UniswapV2Router(ROUTER).swapExactTokensForTokens(amount0, min_amount1, _path, self, block.timestamp)
    amount1: uint256 = amounts[last_index]
    assert amount1 > 0
    deposit_id: uint256 = self.deposits_user[msg.sender]
    if deposit_id == 0:
        deposit_id = self.deposit_size + 1
        self.deposits[deposit_id] = Deposit({
            path: path,
            amount1: amount1,
            depositor: msg.sender,
            deposit_time: block.timestamp,
            duration: duration
        })
        unlock_time: uint256 = block.timestamp + duration
        VeSDT(veSDT).create_lock(amount1, unlock_time)
    else:
        if duration == 0:
            
        deposit: Deposit = self.deposits[deposit_id]
        deposit.amount1 += amount1
        self.deposits[deposit_id] = Deposit({
            path: path,
            amount1: amount1,
            depositor: msg.sender,
            deposit_time: block.timestamp,
            duration: duration
        })
        VeSDT(veSDT).create_lock(amount1, unlock_time)
    self.deposit_size = deposit_id
    self._safe_approve(SDT, veSDT, amount1)
    
    
    log Deposited(deposit_id, token0, amount0, amount1, msg.sender, unlock_time)

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)