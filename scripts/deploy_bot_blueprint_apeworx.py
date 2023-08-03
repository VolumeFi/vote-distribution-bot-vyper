from ape import accounts, project, networks
from typing import Union


def main():
    acct = accounts.load("deployer_account")
    initcode = get_blueprint_initcode(project.vote_distribution_bot.contract_type.deployment_bytecode.bytecode)
    max_base_fee = networks.active_provider.base_fee * 2
    kw = {
        'max_fee': max_base_fee,
        'max_priority_fee': min(int(0.1e9), max_base_fee)}
    tx = project.provider.network.ecosystem.create_transaction(
        chain_id=project.provider.chain_id,
        data=initcode,
        nonce=acct.nonce,
        **kw
    )
    receipt = acct.call(tx)
    print(receipt)


def get_blueprint_initcode(initcode: Union[str, bytes]):
    if isinstance(initcode, str):
        initcode = bytes.fromhex(initcode[2:])
    initcode = b"\xfe\x71\x00" + initcode
    initcode = (
        b"\x61" + len(initcode).to_bytes(2, "big") +
        b"\x3d\x81\x60\x0a\x3d\x39\xf3" + initcode
    )
    return initcode
