# Copilot Instructions for Foundry ERC20 Project

## Project Context
- **Framework**: Foundry (Forge, Cast, Anvil, Chisel)
- **Language**: Solidity `0.8.26`
- **Core Logic**: ERC20 Token implementation using OpenZeppelin Contracts.

## Architecture & Structure
- **Contracts** (`src/`): Contains the smart contracts. `OurToken.sol` is the main ERC20 contract.
- **Scripts** (`script/`): Deployment scripts inheriting from `Script`. `DeployOurToken.s.sol` handles deployment.
- **Tests** (`test/`): Foundry tests inheriting from `Test`. `OurTokenTest.t.sol` contains unit and integration tests.
- **Configuration**: `foundry.toml` manages build settings and remappings.

## Workflows & Commands
- **Build**: `make build` (wraps `forge build`)
- **Test**: `make test` (wraps `forge test`)
- **Deploy (Local)**: `make deploy` (deploys to local Anvil node)
- **Deploy (Sepolia)**: `make deploy-sepolia` (requires `.env` vars: `SEPOLIA_RPC_URL`, `ACCOUNT`, `SENDER`, `ETHERSCAN_API_KEY`)
- **ZkSync**: `make test-zk`, `make deploy-zk` for ZkSync specific operations.

## Development Patterns

### Testing
- **Integration-Style Setup**: Always use the deployment script in `setUp()` to ensure tests run against the production deployment logic.
  ```solidity
  function setUp() public {
      deployer = new DeployOurToken();
      ourToken = deployer.run();
      // ... setup initial balances
  }
  ```
- **User Simulation**: Use `makeAddr("name")` to create test users and `vm.prank(user)` to simulate transactions from them.
- **Assertions**: Use `assertEq` for state verification.

### Deployment
- **Script Structure**: Deployment scripts should return the deployed contract instance to be used by tests.
- **Broadcasting**: Use `vm.startBroadcast()` and `vm.stopBroadcast()` to wrap transaction creation in scripts.

### Dependencies
- **OpenZeppelin**: Use `@openzeppelin/contracts` for standard implementations (ERC20).
- **Foundry DevOps**: Available in `lib/foundry-devops` for CI/CD tooling.

## Style & Conventions
- **Solidity Version**: Lock to `0.8.26`.
- **Remappings**: Managed in `foundry.toml` (e.g., `@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/`).
- **Formatting**: Run `make format` to enforce style.
