# @version 0.3.7

blueprint: public(address)
compass: public(address)
bot_to_owner: public(HashMap[address, address])
owner_to_bot: public(HashMap[address, address])

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event DeployVoteDistributionBot:
    bot: address
    router: address
    deployer: address

event Deposited:
    owner: address
    token0: address
    amount0: uint256
    amount1: uint256
    unlock_time: uint256

event Claimed:
    owner: address
    out_token: address
    out_amount: uint256

@external
def __init__(_blueprint: address, _compass: address):
    self.blueprint = _blueprint
    self.compass = _compass
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)

@external
def deploy_vote_distribution_bot(router: address):
    assert self.owner_to_bot[msg.sender] == empty(address), "Already user has bot"
    bot: address = create_from_blueprint(self.blueprint, self.compass, router, msg.sender, code_offset=3)
    self.bot_to_owner[bot] = msg.sender
    self.owner_to_bot[msg.sender] = bot
    log DeployVoteDistributionBot(bot, router, msg.sender)

@external
def deposited(token0: address, amount0: uint256, amount1: uint256, unlock_time: uint256):
    owner: address = self.bot_to_owner[msg.sender]
    assert owner != empty(address)
    log Deposited(owner, token0, amount0, amount1, unlock_time)

@external
def claimed(out_token: address, amount0: uint256):
    owner: address = self.bot_to_owner[msg.sender]
    assert owner != empty(address)
    log Claimed(owner, out_token, amount0)

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_blueprint(new_blueprint: address):
    assert msg.sender == self.compass
    old_blueprint:address = self.blueprint
    self.blueprint = new_blueprint
    log UpdateCompass(old_blueprint, new_blueprint)
