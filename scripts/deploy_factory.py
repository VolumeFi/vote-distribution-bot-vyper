from brownie import accounts, factory


def main():
    acct = accounts.load("deployer_account")
    blueprint = "0x0000000000000000000000000000000000000000"
    compass = "0x0000000000000000000000000000000000000000"
    factory.deploy(blueprint, compass, {"from": acct})