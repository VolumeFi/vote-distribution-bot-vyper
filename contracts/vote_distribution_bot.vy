# @version 0.3.7

interface WrappedEth:
    def deposit(): payable

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(spender: address, amount: uint256) -> bool: nonpayable

interface VeSDT:
    def create_lock(_value: uint256, _unlock_time: uint256): nonpayable
    def increase_amount(_value: uint256): nonpayable
    def increase_unlock_time(_unlock_time: uint256): nonpayable
    def withdraw(): nonpayable

interface Factory:
    def deposited(token0: address, amount0: uint256, amount1: uint256, unlock_time: uint256): nonpayable
    def claimed(out_token: address, amount0: uint256): nonpayable
    def withdrawn(sdt_amount: uint256, out_token: address, amount0: uint256): nonpayable

interface GaugeController:
    def vote_for_gauge_weights(_gauge_addr: address, _user_weight: uint256): nonpayable

interface FeeDistributor:
    def claim() -> uint256: nonpayable

interface RewardVault:
    def withdrawAll(): nonpayable

interface ZapDepositor:
    def remove_liquidity_one_coin(_pool: address, _burn_amount: uint256, i: int128, _min_amount: uint256, _receiver: address) -> uint256: nonpayable

interface UniswapV2Router:
    def WETH() -> address: pure
    def swapExactTokensForTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256) -> DynArray[uint256, MAX_SIZE]: nonpayable
    def swapExactTokensForETH(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256) -> DynArray[uint256, MAX_SIZE]: nonpayable

SDT: constant(address) = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F
veSDT: constant(address) = 0x0C30476f66034E11782938DF8e4384970B6c9e8a
GAUGECONTROLLER: constant(address) = 0x75f8f7fa4b6DA6De9F4fE972c811b778cefce882
FEE_DISTRIBUTOR: constant(address) = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92
REWARD_VAULT: constant(address) = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7
REWARD_LP_TOKEN: constant(address) = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B
CURVE_ZAP_DEPOSITOR: constant(address) = 0xA79828DF1850E8a3A3064576f380D90aECDD3359
CURVE_FRAX_POOL: constant(address) = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B
USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
MAX_SIZE: constant(uint256) = 8
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
WETH: immutable(address)
ROUTER: immutable(address)
OWNER: immutable(address)
FACTORY: public(immutable(address))
locked_amount: public(uint256)
unlock_time: public(uint256)
gauge_addr: public(DynArray[address, MAX_SIZE])
user_weight: public(DynArray[uint256, MAX_SIZE])

@external
def __init__(router: address, owner: address):
    ROUTER = router
    WETH = UniswapV2Router(ROUTER).WETH()
    OWNER = owner
    FACTORY = msg.sender

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
def _safe_transfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("transfer(address,uint256)")),
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
def swap_lock(path: DynArray[address, MAX_SIZE], amount0: uint256, min_amount1: uint256, unlock_time: uint256):
    assert msg.sender == OWNER
    amount1: uint256 = amount0
    token0: address = empty(address)
    if len(path) == 0:
        self._safe_transfer_from(SDT, msg.sender, self, amount0)
    else:
        _path: DynArray[address, MAX_SIZE] = path
        token0 = path[0]
        last_index: uint256 = unsafe_sub(len(path), 1)
        assert len(path) >= 2 and path[last_index] == SDT, "Wrong path"
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
        self._safe_approve(_path[0], ROUTER, amount0)
        amounts: DynArray[uint256, MAX_SIZE] = UniswapV2Router(ROUTER).swapExactTokensForTokens(amount0, min_amount1, _path, self, block.timestamp)
        amount1 = amounts[last_index]
        assert amount1 > 0
    ERC20(SDT).approve(veSDT, amount1)
    _locked_amount: uint256 = self.locked_amount
    if _locked_amount == 0:
        self.locked_amount = amount1
        self.unlock_time = unlock_time
        VeSDT(veSDT).create_lock(amount1, unlock_time)
    else:
        VeSDT(veSDT).increase_amount(amount1)
        if unlock_time != 0:
            VeSDT(veSDT).increase_unlock_time(unlock_time)
        self.locked_amount = _locked_amount + amount1
    Factory(FACTORY).deposited(token0, amount0, amount1, unlock_time)

@external
def vote(_gauge_addr: DynArray[address, MAX_SIZE], _user_weight: DynArray[uint256, MAX_SIZE]):
    assert msg.sender == FACTORY
    assert len(_gauge_addr) == len(_user_weight), "Wrong array length"
    old_gauge_addr: DynArray[address, MAX_SIZE] = self.gauge_addr
    old_user_weight: DynArray[uint256, MAX_SIZE] = self.user_weight
    is_different: bool = False
    if len(old_gauge_addr) == len(_gauge_addr):
        for i in range(MAX_SIZE):
            if i == len(old_gauge_addr):
                break
            if old_gauge_addr[i] != _gauge_addr[i] or old_user_weight[i] != _user_weight[i]:
                is_different = True
                break
        assert is_different, "Duplicated vote"
    for i in range(MAX_SIZE):
        if i == len(old_gauge_addr):
            break
        GaugeController(GAUGECONTROLLER).vote_for_gauge_weights(old_gauge_addr[i], 0)
    for i in range(MAX_SIZE):
        if i == len(_gauge_addr):
            break
        GaugeController(GAUGECONTROLLER).vote_for_gauge_weights(_gauge_addr[i], _user_weight[i])
    self.gauge_addr = _gauge_addr
    self.user_weight = _user_weight

@external
@nonreentrant("lock")
def claim(path: DynArray[address, MAX_SIZE], _min_amount: uint256) -> uint256:
    assert msg.sender == OWNER
    FeeDistributor(FEE_DISTRIBUTOR).claim()
    RewardVault(REWARD_VAULT).withdrawAll()
    _amount: uint256 = ERC20(REWARD_LP_TOKEN).balanceOf(self)
    self._safe_approve(REWARD_LP_TOKEN, CURVE_ZAP_DEPOSITOR, _amount)
    ZapDepositor(CURVE_ZAP_DEPOSITOR).remove_liquidity_one_coin(CURVE_FRAX_POOL, _amount, 2, 1, OWNER)
    _amount = ERC20(USDC).balanceOf(self)
    assert _amount > 0, "Nothing to claim"
    assert path[0] == USDC, "Wrong path"
    if len(path) >= 2:
        assert len(path) >= 2, "Wrong path"
        self._safe_approve(USDC, ROUTER, _amount)
        last_index: uint256 = unsafe_sub(len(path), 1)
        _path: DynArray[address, MAX_SIZE] = path
        amount0: uint256 = 0
        if path[last_index] == VETH:
            _path[last_index] = WETH
            amount0 = OWNER.balance
            UniswapV2Router(ROUTER).swapExactTokensForETH(_amount, _min_amount, _path, OWNER, block.timestamp)
            amount0 = OWNER.balance - amount0
        else:
            amount0 = ERC20(path[last_index]).balanceOf(OWNER)
            UniswapV2Router(ROUTER).swapExactTokensForTokens(_amount, _min_amount, _path, OWNER, block.timestamp)
            amount0 = ERC20(path[last_index]).balanceOf(OWNER) - amount0
        Factory(FACTORY).claimed(path[last_index], amount0)
        return amount0
    else:
        self._safe_transfer(USDC, OWNER, _amount)
        return _amount

@external
@nonreentrant("lock")
def withdraw(path: DynArray[address, MAX_SIZE], _min_amount: uint256) -> uint256:
    assert msg.sender == OWNER
    _amount: uint256 = ERC20(SDT).balanceOf(self)
    VeSDT(veSDT).withdraw()
    _amount = ERC20(SDT).balanceOf(self) - _amount
    assert _amount > 0, "Insufficient withdraw amount"
    self.locked_amount -= _amount
    self._safe_approve(SDT, ROUTER, _amount)
    last_index: uint256 = unsafe_sub(len(path), 1)
    assert len(path) >= 2, "Wrong path"
    _path: DynArray[address, MAX_SIZE] = path
    amount0: uint256 = 0
    if path[last_index] == VETH:
        _path[last_index] = WETH
        amount0 = OWNER.balance
        UniswapV2Router(ROUTER).swapExactTokensForETH(_amount, _min_amount, _path, OWNER, block.timestamp)
        amount0 = OWNER.balance - amount0
    else:
        amount0 = ERC20(path[last_index]).balanceOf(OWNER)
        UniswapV2Router(ROUTER).swapExactTokensForTokens(_amount, _min_amount, _path, OWNER, block.timestamp)
        amount0 = ERC20(path[last_index]).balanceOf(OWNER) - amount0
    Factory(FACTORY).withdrawn(_amount, path[last_index], amount0)
    return amount0