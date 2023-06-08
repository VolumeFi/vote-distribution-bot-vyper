# Vote Distribution Bot

## Dependencies

[Brownie](https://github.com/eth-brownie/brownie)

[Ganache](https://github.com/trufflesuite/ganache)

## vote_distribution_bot.vy

### Read-Only functions

### FACTORY

| Key        | Type    | Description                      |
| ---------- | ------- | -------------------------------- |
| **Return** | address | Returns factory contract address |


### compass

| Key        | Type    | Description                                |
| ---------- | ------- | ------------------------------------------ |
| **Return** | address | Returns compass-evm smart contract address |

### locked_amount

| Key        | Type    | Description               |
| ---------- | ------- | ------------------------- |
| **Return** | uint256 | Returns locked SDT amount |

### unlock_time

| Key        | Type    | Description                       |
| ---------- | ------- | --------------------------------- |
| **Return** | uint256 | Returns unlock timestamp in veSDT |

## State-Changing functions

### swap_lock

Deposit a token with swap path to SDT in Uniswap and amount. This is run by users.

| Key         | Type      | Description                                 |
| ----------- | --------- | ------------------------------------------- |
| path        | address[] | Initial token swap path via Uniswap V2      |
| amount0     | uint256   | Deposit token amount                        |
| min_amount1 | uint256   | Expected token amount from the initial swap |
| unlock_time | uint256   | Unlock time for veSDT                       |

### vote

Vote to the gauge. This is run by Compass-EVM only.

| Key          | Type    | Description               |
| ------------ | ------- | ------------------------- |
| _gauge_addr  | address | Gauge address of StakeDAO |
| _user_weight | uint256 | User weight for the gauge |

### claim

Claim reward, swap and send the token to the depositor. This is run by users.

| Key         | Type    | Description                                                    |
| ----------- | ------- | -------------------------------------------------------------- |
| path        | uint256 | token swap path from USDC to the expected token via Uniswap V2 |
| _min_amount | uint256 | Mininum amount of original token to receive on withdraw        |
| ----------  | ------- | ------------------------                                       |
| **Return**  | uint256 | Claimed token amount                                           |

### withdraw

Withdraw SDT, swap and send the token to the depositor. This is run by users.

| Key         | Type    | Description                                                   |
| ----------- | ------- | ------------------------------------------------------------- |
| path        | uint256 | token swap path from SDT to the expected token via Uniswap V2 |
| _min_amount | uint256 | Mininum amount of original token to receive on withdraw       |
| ----------  | ------- | ------------------------                                      |
| **Return**  | uint256 | Withdrawn token amount                                        |

### update_compass

Update Compass-EVM address.  This is run by Compass-EVM only.

| Key         | Type    | Description             |
| ----------- | ------- | ----------------------- |
| new_compass | address | New compass-evm address |

## factory.vy

### Read-Only functions

### blueprint

| Key        | Type    | Description                        |
| ---------- | ------- | ---------------------------------- |
| **Return** | address | Returns blueprint contract address |


### compass

| Key        | Type    | Description                                |
| ---------- | ------- | ------------------------------------------ |
| **Return** | address | Returns compass-evm smart contract address |

### bot_to_owner

| Key        | Type    | Description               |
| ---------- | ------- | ------------------------- |
| arg0       | uint256 | Returns locked SDT amount |
| **Return** | uint256 | Returns locked SDT amount |

### unlock_time

| Key        | Type    | Description                       |
| ---------- | ------- | --------------------------------- |
| **Return** | uint256 | Returns unlock timestamp in veSDT |

## State-Changing functions

### deploy_vote_distribution_bot

Deploy a vote distribution bot for users. This is run by users.

| Key    | Type    | Description               |
| ------ | ------- | ------------------------- |
| router | address | Uniswap V2 Router address |

### deposited

Emit event for deposit. This is run by bot smart contracts.

| Key          | Type    | Description               |
| ------------ | ------- | ------------------------- |
| _gauge_addr  | address | Gauge address of StakeDAO |
| _user_weight | uint256 | User weight for the gauge |

### claimed

Emit event for claim. This is run by bot smart contracts.

| Key       | Type    | Description                   |
| --------- | ------- | ----------------------------- |
| out_token | address | Receiving token from claiming |
| amount0   | uint256 | Received amount               |

### withdraw

Emit event for withdraw. This is run by bot smart contracts.

| Key        | Type    | Description                      |
| ---------- | ------- | -------------------------------- |
| sdt_amount | uint256 | Unlocked SDT token amount        |
| out_token  | address | Receiving token from withdrawing |
| amount0    | uint256 | Received amount                  |

### update_compass

Update Compass-EVM address.  This is run by Compass-EVM only.

| Key         | Type    | Description             |
| ----------- | ------- | ----------------------- |
| new_compass | address | New compass-evm address |

### update_blueprint

Update blueprint address.  This is run by Compass-EVM only.

| Key           | Type    | Description           |
| ------------- | ------- | --------------------- |
| new_blueprint | address | New blueprint address |