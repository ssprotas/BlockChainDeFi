# Vega Voting ProtocolHW

Here is the script how i deployed the contract

## Go to project dir if not done yet
```
cd HW2
```

## Install OpenZeppelin contracts if not done yet
```
forge install OpenZeppelin/openzeppelin-contracts
```

## Build
```
forge build
```

## Test
```
forge test
```

## Set env vars
```powershell
$env:SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/..."
$env:PRIVATE_KEY="0x..."
$env:ETHERSCAN_API_KEY="..."
```

or

```bash
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/..."
export PRIVATE_KEY="0x..."
export ETHERSCAN_API_KEY="..."
```

## Run deployment script

```powershell
forge script script/DeployVotingSystem.s.sol:DeployVotingSystem `
    --rpc-url $env:SEPOLIA_RPC_URL `
    --private-key $env:PRIVATE_KEY `
    --broadcast `
    --verify `
    --etherscan-api-key $env:ETHERSCAN_API_KEY
```

or 

```bash
forge script script/DeployVotingSystem.s.sol:DeployVotingSystem \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

The trasnaction logs saved to broadcats dir as run-latest.json.

Deployed contracts addresses:
```
  VVToken deployed at: 0x9EE3c142B7E35989cdD6DA5D2a0737d3e59932F2
  StakingManager deployed at: 0x67fc7A5E415C7379e255ec49f1028C04E001eDFB
  VotingResultNFT deployed at: 0x82F3920b72e27AB225e8F6ec68d1ca08D51b468B
  VotingContract deployed at: 0xd62cd4c3E9149E0144AbfFfF84529331f522D4A8
```