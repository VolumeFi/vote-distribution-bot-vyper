from ape import accounts, project, networks


def main():
    acct = accounts.load("deployer_account")
    max_base_fee = networks.active_provider.base_fee * 2
    kw = {
        'max_fee': max_base_fee,
        'max_priority_fee': min(int(0.1e9), max_base_fee)}
    blueprint = "0xaB595f0bF1D7787a0a39243074A820378aFE1504"
    compass = "0x7Eec3e2f4d567794B927B6d904Fbf973bC8D15e6"
    tx = acct.deploy(project.factory, blueprint, compass, kwargs=kw)
    print(tx)
