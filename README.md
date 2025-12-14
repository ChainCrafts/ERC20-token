# Foundry ERC20 (OurToken + ManualToken)

Minimal Foundry project that implements and tests two ERC20 tokens:

- `OurToken` ([src/OurToken.sol](src/OurToken.sol)) — OpenZeppelin ERC20 with an initial supply of `1_000_000e18` minted to the deployer.
- `ManualToken` ([src/ManualToken.sol](src/ManualToken.sol)) — step-by-step ERC20 implementation (balances, allowances, events).

Deployment is handled via [script/DeployOurToken.s.sol](script/DeployOurToken.s.sol). Tests live under [test](test).

## Prerequisites

- Foundry installed: https://book.getfoundry.sh/getting-started/installation

## Quickstart

```bash
make build
make test
```

## Local deploy (Anvil)

Terminal 1:

```bash
make anvil
```

Terminal 2:

```bash
make deploy
```

## Useful commands

```bash
make format
make snapshot
forge test -vvvv
```
