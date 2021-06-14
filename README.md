# Kitty Auction House

👋 Welcome! This is an Auction House for Kitty Items NFT Marketplace.

- Kitty Auction House is a **complete NFT marketplace & auction house** built with [Cadence](https://docs.onflow.org/cadence), Flow's resource-oriented smart contract programming language.

## 😺 What are Kitty Items?

Items are hats for your cats, but under the hood they're [non-fungible tokens (NFTs)](https://github.com/onflow/flow-nft) stored on the Flow blockchain.

Items can be purchased from the marketplace with fungible tokens.
In the future you'll be able to add them to [Ethereum CryptoKitties](https://www.cryptokitties.co/) with ownership validated by an oracle.

## What is Kitty Auction House?
The Kitty Auction House is an open and permissionless system that allows any creator, community, platform or DAO to create and run their own curated auction houses.

These auction houses run reserve timed auctions for NFTs, with special emphasis given to the role of curators. If an owner of an NFT chooses to list with a curator, that curator can charge a curator fee and has to approve any auction before it commences with that curators auction house.

Anyone is able to run an NFT auction on the protocol for free by simply not specifying a curator.

## Architecture
Architecture
This protocol allows a holder of any NFT to create and perform a permissionless reserve auction. It also acknowledges the role of curators in auctions, and optionally allows the auction creator to dedicate a portion of the winnings from the auction to a curator of their choice.

Note that if a curator is specified, the curator decides when to start the auction. Additionally, the curator is able to cancel an auction before it begins.

## Curators
In a metaverse of millions of NFTs, the act of curation is critical. Curators create and facilitate context and community which augment the value of NFTs that they select. The act of curation creates value for the NFT by contextualizing it and signalling its importance to a particular community. The act of curation is extremely valuable, and is directly recognized by the Auction House system. A curator who successfully auctions off an NFT for an owner can earn a share in the sale.

We have defined a curator role in the auction house. A curator can:

Approve and deny proposals for an NFT to be listed with them.
Earn a fee for their curation
Cancel an auction prior to bidding being commenced
Creators and collectors can submit a proposal to list their NFTs with a curator onchain, which the curator must accept (or optionally reject). This creates an onchain record of a curators activity and value creation.

Creators and collectors always have the option to run an auction themselves for free.

## ✨ Getting Started

### 1. Install the Flow CLI

Before you start, install the [Flow command-line interface (CLI)](https://docs.onflow.org/flow-cli).

_⚠️ This project requires `flow-cli v0.15.0` or above._

### 2. Clone the project

```sh
git clone https://github.com/onflow/kitty-items.git
```

### 3. Create a Flow Testnet account

You'll need a Testnet account to work on this project. Here's how to make one:

#### Generate a key pair 

Generate a new key pair with the Flow CLI:

```sh
flow keys generate
```

_⚠️ Make sure to save these keys in a safe place, you'll need them later._

#### Create your account

Go to the [Flow Testnet Faucet](https://testnet-faucet-v2.onflow.org/) to create a new account. Use the **public key** from the previous step.

#### Save your keys

After your account has been created, save the address and private key to the following environment variables:

```sh
# Replace these values with your own!
export FLOW_ADDRESS=0xabcdef12345689
export FLOW_PRIVATE_KEY=xxxxxxxxxxxx
```

### 4. Deploy the contracts

```sh
flow project deploy --network=testnet
```

If you'd like to look at the contracts in your account, to confirm that everything was deploy properly, you can use the following cli command:
```sh
flow accounts get $FLOW_ADDRESS --network=testnet
```

### 5. Run the API

After the contracts are deployed, follow the [Kitty Items API instructions](https://github.com/onflow/kitty-items/tree/master/api#readme)
to install and run the Kitty Items API. This backend service is responsible for initializing accounts, minting NFTs, and processing events.

### 6. Launch the web app

Lastly, follow the [Kitty Items Web instructions](https://github.com/onflow/kitty-items/tree/master/web#readme) to launch the Kitty Items front-end React app.

### (Optional) Heroku Deployment

If you'd like to deploy a version of this app to Heroku for testing, you can use this button!

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

You'll need to supply the following configuration variables when prompted: 

```bash
# The Flow address and private key you generated above

MINTER_ADDRESS
MINTER_PRIVATE_KEY

# The Flow address where you have deployed your Kitty Items contract.
# (usually the same Flow address as above)

REACT_APP_CONTRACT_KIBBLE
REACT_APP_CONTRACT_KITTY_ITEMS
REACT_APP_CONTRACT_KITTY_ITEMS_MARKET
```

---

🚀 Happy Hacking!
