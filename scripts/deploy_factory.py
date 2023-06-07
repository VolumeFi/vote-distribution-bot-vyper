from brownie import accounts, factory
from eth_abi import encode_abi

def main():
    acct = accounts.load("deployer_account")
    blueprint = "0x0000000000000000000000000000000000000000"
    compass = "0x0000000000000000000000000000000000000000"
    factory.deploy(blueprint, compass, {"from": acct})