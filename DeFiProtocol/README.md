## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```



// This is how our Stable coin will work.

1. Relative Stability: Anchored or Pegged -> $1.00
    1. To keep the price of the coin as the current value we are going to use Cahinlink Price feed. 
    2. Set a function to exchange ETH & BTC -> $$$
2. Stability Mechanism (Minting): Algorithmic (Decentralized)
    1. People can only mint the stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    1. wETH (wraped ETH)
    2. wBTC (wraped BTC)


- calculate health factor fucntion
- set health factor if debt is 0
- added a bunch of view function

1. What are our invariats/properties?