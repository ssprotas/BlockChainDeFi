# Onchain Git

Here is the script how i deployed the contract, upgraded ir and made a rollback

## Go to project dir if not done yet

```
cd HW3
```

## Install OpenZeppelin deps if not done yet

```
forge install OpenZeppelin/openzeppelin-contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

or

```
git submodule update --init --recursive
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
forge script script/Deploy.s.sol --rpc-url $env:SEPOLIA_RPC_URL --broadcast
```

or

```bash
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

Hashes from sepolia:
```
##### sepolia
✅  [Success] Hash: 0xf74e4049633ae070684b20138df6bb81698b651b862457db3317e3a319a44b40      
Contract Address: 0xf7d376f7eF9E4253d779558a8443dF7418b011a6
Block: 10577413
Paid: 0.000000332168989494 ETH (332166 gas * 0.001000009 gwei)

##### sepolia
✅  [Success] Hash: 0x57e56c167ed569b5d5d9dfb1fd46a2bcb61df814c56fd03ac99ded0f29f46480      
Contract Address: 0x9c25371b7b7CBa8657F9c9957bD50aE88d8F7A5b                                
Block: 10577413                                                                             
Paid: 0.000001089263803286 ETH (1089254 gas * 0.001000009 gwei)

##### sepolia
✅  [Success] Hash: 0x71190fb267dd9d4c5970db809cbfb2008de29665187f25bb556b30cf58bbd2e7      
Contract Address: 0xEd73fC340ED2F2d53d01169775A8003A6DcFFdF5                                
Block: 10577413
Paid: 0.000000423969815694 ETH (423966 gas * 0.001000009 gwei)

##### sepolia
✅  [Success] Hash: 0x94b62eae8688d0c60a51647862fa31faaae567aa6ea258dcc72c0dbc29fb8572      
Contract Address: 0x8dD016eB8DD030Cfa9667A95cDEB0b00f21ebf84                                
Block: 10577413
Paid: 0.000000405998653955 ETH (405995 gas * 0.001000009 gwei)
```

Logs and deployed addresses:
```
== Logs ==
  Deploying TokenV1...
  TokenV1 deployed at: 0x9c25371b7b7CBa8657F9c9957bD50aE88d8F7A5b
  Deploying VersionedProxy...
  VersionedProxy deployed at: 0xEd73fC340ED2F2d53d01169775A8003A6DcFFdF5
  Deploying VersionedBeacon...
  VersionedBeacon deployed at: 0x8dD016eB8DD030Cfa9667A95cDEB0b00f21ebf84
  Deploying BeaconProxy...
  BeaconProxy deployed at: 0xf7d376f7eF9E4253d779558a8443dF7418b011a6

=== Deployment Addresses ===
  TokenV1: 0x9c25371b7b7CBa8657F9c9957bD50aE88d8F7A5b
  VersionedProxy: 0xEd73fC340ED2F2d53d01169775A8003A6DcFFdF5
  VersionedBeacon: 0x8dD016eB8DD030Cfa9667A95cDEB0b00f21ebf84
  BeaconProxy: 0xf7d376f7eF9E4253d779558a8443dF7418b011a6
```

## Run upgrade script

```powershell
$env:PROXY_ADDRESS="0x290Ab652cA950e38eE846b24f3Ae0f0e81523b01"
$env:UPGRADE_TYPE="v2"
```

or

```bash
export $PROXY_ADDRESS="0x290Ab652cA950e38eE846b24f3Ae0f0e81523b01"
export $UPGRADE_TYPE="v2"
```

Now we can run the upgrade script:

```powershell
forge script script/Upgrade.s.sol --rpc-url $env:SEPOLIA_RPC_URL --broadcast
```

or

```bash
forge script script/Upgrade.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

Hashes from sepolia:
```
##### sepolia
✅  [Success] Hash: 0x0775d1540c66fc677fbe31df9fb5c3092cfc3b5f1871ed5422651b6dbc105d00      
Block: 10577424
Paid: 0.000000077506697554 ETH (77506 gas * 0.001000009 gwei)

##### sepolia
✅  [Success] Hash: 0xd2ce6d3f98cf6ed55931896b0e7750985b5b48ec18a7204cf766c584e0ab157b      
Contract Address: 0xa00a72e84F526b3bFc001d5451E028f8C5d73c82
Block: 10577424
Paid: 0.000001168496516374 ETH (1168486 gas * 0.001000009 gwei)
```

Logs:
```
== Logs ==
  Deploying TokenV2...
  TokenV2 deployed at: 0xa00a72e84F526b3bFc001d5451E028f8C5d73c82
  Upgrading proxy...
  Upgraded to version index: 2
  Current implementation: 0xa00a72e84F526b3bFc001d5451E028f8C5d73c82
```


## Run the rollback to V1

```powerhshell
$env:VERSION_INDEX="0"
```

or

```bash
export $VERSION_INDEX="0"
```

Run the script:

```powershell
forge script script/Rollback.s.sol --rpc-url $env:SEPOLIA_RPC_URL --broadcast
```

or 

```bash
forge script script/Rollback.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

Hash from sepolia:
```
##### sepolia
✅  [Success] Hash: 0xe9926ebb153df8713a73eed15352f50b17e46c46170642e414ca3ffc37092073      
Block: 10577430
Paid: 0.000000032359258872 ETH (32359 gas * 0.001000008 gwei)
```

Logs from rolling back to V1(index=0):
```
== Logs ==
  Rolling back to version index: 0
  Rolled back successfully!
  Current version index: 0
  Target version was: 0
  Current implementation: 0x26eB75B101ef30E985e5A3d35A8CaF858670c3EA
```