# DEX aggregator

## Go to project dir if not done yet

```
cd Project1
```

## Install OpenZeppelin deps if not done yet

```
forge install OpenZeppelin/openzeppelin-contracts
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

## Run deployment script without verification for testing

```powershell
forge script script/Deploy.s.sol:Deploy --rpc-url $env:SEPOLIA_RPC_URL --private-key $env:PRIVATE_KEY --broadcast
```

or

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Logs:
```
  Deployer address: 0x8666a2e7459bCCCC8efaD0214fE3C8C57D6d002F
  Network: Sepolia Testnet

  Deploying DEX Aggregator
  UniswapV2 Factory: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  UniswapV2 Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  UniswapV3 Factory: 0x1f98431C8ad98523631AE4a59F267346Ea31fAbe
  UniswapV3 Router: 0x68B3465833fb72B5a828cFB67D4C6F15C3B29139

  DEX aggregator deployed at: 0x0642a59f3B393Af70bdaDa9cc1440a27608f7157

    DEX aggregator address: 0x0642a59f3B393Af70bdaDa9cc1440a27608f7157
  Owner: 0x8666a2e7459bCCCC8efaD0214fE3C8C57D6d002F
```

Hashes from sepolia:
```
##### sepolia
✅  [Success] Hash: 0xaffeca243ceb4cb17552b1f084d8874fccae0d78714433f86b39b9559d0e57bb
Block: 10666206
Paid: 0.000000568138755414 ETH (26274 gas * 0.021623611 gwei)

##### sepolia
✅  [Success] Hash: 0xfa5f85e42b521917e168a59bc9cb55300b343f0647414efe3a1392044a8a078f
Block: 10666206
Paid: 0.000000568138755414 ETH (26274 gas * 0.021623611 gwei)

##### sepolia
✅  [Success] Hash: 0x47f37bd504ebd995a3e5767784fe03b0db947457464c4b4e2bb1429a7975ba47                                                                                    
Block: 10666206                                                                      
Paid: 0.000000597287383042 ETH (27622 gas * 0.021623611 gwei)

##### sepolia
✅  [Success] Hash: 0x81393a047a617588f92b606a121aeefe3e6d784a0265b3c82be5cb1f65c35cf1                                                                                    
Contract Address: 0x0642a59f3B393Af70bdaDa9cc1440a27608f7157                         
Block: 10666206
Paid: 0.000052269414206418 ETH (2417238 gas * 0.021623611 gwei)

##### sepolia
✅  [Success] Hash: 0xb687a639751fc954334bae13b3bf73b32194f7f4fa7ea6ef1fd989f71d31d1a9                                                                                    
Block: 10666206
Paid: 0.000000568138755414 ETH (26274 gas * 0.021623611 gwei)

##### sepolia
✅  [Success] Hash: 0xdc06c5da51a7a9045657686ac054abdb9b5a181bd5a18b1b2a98469a560930ff
Block: 10666206
Paid: 0.000000585437644214 ETH (27074 gas * 0.021623611 gwei)
```


## Run deployment script with verification

```powershell
forge script script/Deploy.s.sol:Deploy --rpc-url $env:SEPOLIA_RPC_URL --private-key $env:PRIVATE_KEY --broadcast --verify --etherscan-api-key $env:ETHERSCAN_API_KEY
```

or

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```


Logs:
```
  Deployer address: 0x8666a2e7459bCCCC8efaD0214fE3C8C57D6d002F
  Network: Sepolia Testnet

  Deploying DEX Aggregator
  UniswapV2 Factory: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  UniswapV2 Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  UniswapV3 Factory: 0x1f98431C8ad98523631AE4a59F267346Ea31fAbe
  UniswapV3 Router: 0x68B3465833fb72B5a828cFB67D4C6F15C3B29139

  DEX aggregator deployed at: 0x29C44EE4c0b62766b42dc2fe5426D0cA864237F8

  Setting protocol fee to 0.25%
  Protocol fee set

  Setting fee recipient to deployer address
  Fee recipient set

  Enabling UniswapV3 fee tiers
  Fee tiers enabled

  DEX aggregator address: 0x29C44EE4c0b62766b42dc2fe5426D0cA864237F8
  Owner: 0x8666a2e7459bCCCC8efaD0214fE3C8C57D6d002F
  Protocol fee: 0.25%
```

Hashes from sepolia:
```
##### sepolia
✅  [Success] Hash: 0xf3a6950a0c8cd5189d4302cbe6da80c20c96964545350768f63c4a5b33874d8b
Block: 10666221
Paid: 0.000000511099110018 ETH (26274 gas * 0.019452657 gwei)

##### sepolia
✅  [Success] Hash: 0x5cc39ceacf32368f3279453048eb8a3edf1c2300b1917555a3e2df86717407da                                                                                    
Block: 10666221                                                                      
Paid: 0.000000537321291654 ETH (27622 gas * 0.019452657 gwei)

##### sepolia
✅  [Success] Hash: 0xf81bc2adbc3b096a0bd723201ef4602cea1a071a6cdcd7e128f86a23d03d29eb                                                                                    
Block: 10666221                                                                      
Paid: 0.000000526661235618 ETH (27074 gas * 0.019452657 gwei)

##### sepolia
✅  [Success] Hash: 0x78052501e2e7f3800a6d389355e7b84c73eafce4a894cd43939c8014b7e6025b                                                                                    
Contract Address: 0x29C44EE4c0b62766b42dc2fe5426D0cA864237F8                         
Block: 10666221
Paid: 0.000047021701701366 ETH (2417238 gas * 0.019452657 gwei)

##### sepolia
✅  [Success] Hash: 0x8458e9dbe633be851c0d07a032dfdd94718678bda204d656dd85900e0fa33832                                                                                    
Block: 10666221
Paid: 0.000000511099110018 ETH (26274 gas * 0.019452657 gwei)

##### sepolia
✅  [Success] Hash: 0x008920994b2e0bcfe8342a1c0fcae9f57860098f0bd324f4c9b918b93833c5b8                                                                                    
Block: 10666221
Paid: 0.000000511099110018 ETH (26274 gas * 0.019452657 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000049618981558692 ETH (2550756 gas * avg 0.019452657 gwei)
```

Verification responses:

```
Submitted contract for verification:
        Response: `OK`
        GUID: `tpccipxj8rnfim1bs5lnnafdq5jewhze8xml6tqmqsby2e3enm`
        URL: https://sepolia.etherscan.io/address/0x29c44ee4c0b62766b42dc2fe5426d0ca864237f8

Submitted contract for verification:
        Response: `OK`
        GUID: `hgezh9x9cjjrpbbarehvezuxcytcjqiduswlfstqgwv8achvsv`
        URL: https://sepolia.etherscan.io/address/0xaa4e0996cd65655f480b1824774a1a7dd69270d1

Submitted contract for verification:
        Response: `OK`
        GUID: `hz4kfhmixihvrdsgxw7ruzcseh4mnqhxbdiiajcnqyvjikvihu`
        URL: https://sepolia.etherscan.io/address/0x3b5d9ffc54a0a4a3a4960ab68698ea1872f3b309
```