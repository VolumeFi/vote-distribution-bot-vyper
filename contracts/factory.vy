# @version 0.3.7

interface Bot:
    def vote(_gauge_addr: DynArray[address, MAX_SIZE], _user_weight: DynArray[uint256, MAX_SIZE], _refund_wallet: address, _fee: uint256, _min_amount: uint256, _max_amount: uint256) -> (address, uint256, uint256): nonpayable

MAX_SIZE: constant(uint256) = 8

blueprint: public(address)
compass: public(address)
bot_to_owner: public(HashMap[address, address])
owner_to_bot: public(HashMap[address, address])
paloma: public(bytes32)
refund_wallet: public(address)
fee: public(uint256)

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event DeployVoteDistributionBot:
    bot: address
    router: address
    owner: address

event Deposited:
    bot: address
    token0: address
    amount0: uint256
    amount1: uint256
    unlock_time: uint256

event Withdrawn:
    bot: address
    sdt_amount: uint256
    out_token: address
    out_amount: uint256

event Voted:
    bot: address
    gauge_addr: DynArray[address, MAX_SIZE]
    user_weight: DynArray[uint256, MAX_SIZE]
    claimed_token: address
    claimed_amount: uint256
    time_stamp: uint256

event SetPaloma:
    paloma: bytes32

@external
def __init__(_blueprint: address, _compass: address):
    self.blueprint = _blueprint
    self.compass = _compass
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)

@external
def deploy_vote_distribution_bot(router: address):
    assert self.owner_to_bot[msg.sender] == empty(address), "Already user has bot"
    bot: address = create_from_blueprint(self.blueprint, router, msg.sender, code_offset=3)
    self.bot_to_owner[bot] = msg.sender
    self.owner_to_bot[msg.sender] = bot
    log DeployVoteDistributionBot(bot, router, msg.sender)

@external
@nonreentrant('lock')
def vote(bots: DynArray[address, MAX_SIZE], _gauge_addr: DynArray[address, MAX_SIZE], _user_weight: DynArray[uint256, MAX_SIZE], min_amount: DynArray[uint256, MAX_SIZE], max_amount: DynArray[uint256, MAX_SIZE]) -> (DynArray[uint256, MAX_SIZE], DynArray[uint256, MAX_SIZE]):
    assert msg.sender == self.compass, "Not compass"
    _len: uint256 = len(_gauge_addr)
    assert _len == len(_user_weight), "Validation error"
    _len = len(bots)
    assert _len == len(min_amount) and _len == len(max_amount), "Validation error"
    _len = unsafe_add(unsafe_add(unsafe_mul(unsafe_add(len(bots), 2), 96), unsafe_mul(unsafe_add(_len, 2), 64)), 36)
    assert len(msg.data) == _len, "Invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(_len, 32), 32), bytes32), "Invalid paloma"
    _refund_wallet: address = self.refund_wallet
    _fee: uint256 = self.fee
    min_amounts: DynArray[uint256, MAX_SIZE] = []
    max_amounts: DynArray[uint256, MAX_SIZE] = []
    _out_token: address = empty(address)
    _min_amount: uint256 = 0
    _max_amount: uint256 = 0
    for i in range(MAX_SIZE):
        if i >= len(bots):
            break
        (_out_token, _min_amount, _max_amount) = Bot(bots[i]).vote(_gauge_addr, _user_weight, _refund_wallet, _fee, min_amount[i], max_amount[i])
        min_amounts.append(_min_amount)
        max_amounts.append(_max_amount)
        log Voted(bots[i], _gauge_addr, _user_weight, _out_token, _min_amount,  block.timestamp)
    return min_amounts, max_amounts

@external
def deposited(token0: address, amount0: uint256, amount1: uint256, unlock_time: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address)
    log Deposited(msg.sender, token0, amount0, amount1, unlock_time)

@external
def withdrawn(sdt_amount: uint256, out_token: address, amount0: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address)
    log Withdrawn(msg.sender, sdt_amount, out_token, amount0)

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_blueprint(new_blueprint: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_blueprint:address = self.blueprint
    self.blueprint = new_blueprint
    log UpdateCompass(old_blueprint, new_blueprint)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)