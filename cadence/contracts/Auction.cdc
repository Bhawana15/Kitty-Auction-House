import FungibleToken from 0x4fc019cea9fc4817
import NonFungibleToken from 0x4fc019cea9fc4817
import Kibble from 0x4fc019cea9fc4817
import KittyItems from 0x4fc019cea9fc4817


pub contract Auction {
    
    pub var totalAuctions : UInt64

    // EVENTS : WRITE HERE
    // pub event newAuctionCreated (auctionID, NFT_ID, Curator_ID, ownerAddress)
    // pub event auctionSettled(auctionID, NFT_ID, Curator_ID, oldOwnerAddress, winnerAddress)
    // pub event auctionCancelled(auctionID, NFT_ID, Curator_ID, ownerAddress)

    pub struct AuctionStatus {
        pub let itemOwner: Address?
        pub let NFT_ID: UInt64?
        pub var auctionID : UInt256
        pub let currentBidAmount : UFix64 
        pub let bidIncrement : UFix64
        pub let timeRemaining : Fix64
        pub var active : Bool
        pub var approved : Bool
        pub var cancelled : Bool
        pub var completed: Bool 
        pub let startTime : Fix64
        pub let endTime : Fix64
        pub let minimumBidIncrement : UInt64
        // pub var recentBidderID : UInt256
        // pub let bids : UInt64 // 
        // pub let metadata: Art.Metadata?
        
        pub let leader: Address?

        init(
            itemOwner : Address?, 
            NFT_ID: UInt64?, 
            auctionID : UInt256,
            currentBidAmount : UFix64,  
            bidIncrement : UFix64, 
            timeRemaining : Fix64, 
            endTime : Fix64, 
            startTime : Fix64, 
            minimumBidIncrement : UInt64
        ) {
            self.itemOwner = itemOwner
            self.NFT_ID = NFT_ID
            self.auctionID = auctionID
            self.currentBidAmount = currentBidAmount
            self.bidIncrement = bidIncrement
            self.timeRemaining = timeRemaining
            self.endTime = endTime
            self.startTime = startTime
            self.approved = false
            self.cancelled = false
            self.active = false
            self.completed = false
            self.minimumBidIncrement = minimumBidIncrement
        }
    }


    pub resource AuctionItem {

        pub var NFT_ID : UInt256
        access(self) var numberOfBids: UInt64
        access(self) var NFT: @KittyItems.NFT?
        pub let auctionID : UInt64
        access(self) let minimumBidIncrement: UFix64
        access(self) var auctionStartTime: UFix64
        access(self) var auctionLength : UFix64
        access(self) var auctionCompleted: Bool
        access(account) var startPrice: UFix64
        priv var currentPrice: UFix64 
        access(self) var recipientCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>?
        access(self) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?
        access(self) let ownerCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>
        access(self) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
        pub var curatorFeePercentage : UInt64
        // pub var curatorAdd : Address

        // Returns Bid Amount to the Bidder and NFT to the Owner if Auction is cancelled
        pub fun returnAuctionItemToOwner() {

            // release the bidder's tokens
            self.releasePreviousBid()

            // deposit the NFT into the owner's collection
            self.sendNFT(self.ownerCollectionCap)
        }
        
        // Returns address of the Bidder
        pub fun bidder() : Address? {
            if let vaultCap = self.recipientVaultCap {
                return vaultCap.borrow()!.owner!.address
            }
            return nil
        }

        // Returns the current Bid
        pub fun currentBidForUser(address:Address): UFix64 {
             if(self.bidder() == address) {
                return self.bidVault.balance
            }
            return 0.0
        }

        pub fun placeBid(
            bidTokens: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        ) {
            pre {
                !self.auctionCompleted : "The auction is already settled"
                Curator.NFT != nil: "NFT in auction does not exist"
            }

            let bidderAddress = vaultCap.borrow()!.owner!.address

            let BiddingAmount = bidTokens.balance
            let minNextBid = self.minNextBid()
            if BiddingAmount < minNextBid {
                panic("bid amount must be larger or equal to the current price + minimum bid increment "
                .concat(amountYouAreBidding.toString()).concat(" < ").concat(minNextBid.toString()))
             }

            if self.bidder() != bidderAddress {
              if self.bidVault.balance != 0.0 {
                self.sendBidTokens(self.recipientVaultCap!)
              }
            }

            // Update the auction item
            Curator.bidVault.deposit(from: <-bidTokens)

            //update the capability of the wallet for the address with the current highest bid
            self.recipientVaultCap = vaultCap

            // Update the current price of the token
            self.currentPrice = Curator.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            self.recipientCollectionCap = collectionCap
            self.numberOfBids=self.numberOfBids+(1 as UInt64)

        //  emit Bid(NFT_ID: self.auctionID, bidderAddress: bidderAddress, bidPrice: self.currentPrice)
        }

        pub fun releasePreviousBid() {
            if let vaultCap = self.recipientVaultCap {
                Curator.sendBidTokens(self.recipientVaultCap!)
                return
            } 
        }

        pub fun isAuctionExpired() : Bool {
            let timeRemaining= self.timeRemaining()
            return timeRemaining < Fix64(0.0)
        }

        pub fun minNextBid() :UFix64 {
            return AuctionItem.minimumBidIncrement + self.currentPrice
        }

        pub fun extendWith(_ amount: UFix64) {
            AuctionStatus.timeRemaining = AuctionStatus.timeRemaining + amount
            AuctionItem.auctionLength = AuctionItem.auctionLength + amount
        }

        pub fun timeRemaining() : Fix64 {
            return Fix64(self.auctionLength) - Fix64(getCurrentBlock.timestamp())
        }

        pub fun getAuctionStatus() :AuctionStatus {
            var leader:Address?= nil
            if let recipient = self.recipientVaultCap {
                leader=recipient.borrow()!.owner!.address
            }

            return AuctionStatus(
                id:self.auctionID,
                currentPrice: self.currentPrice, 
                bids: self.numberOfBids,
                active: !self.auctionCompleted  && !self.isAuctionExpired(),
                timeRemaining: self.timeRemaining(),
                metadata: self.NFT?.metadata,
                artId: self.NFT?.id,
                leader: leader,
                bidIncrement: self.minimumBidIncrement,
                owner: self.ownerVaultCap.borrow()!.owner!.address,
                startTime: Fix64(self.auctionStartTime),
                endTime: Fix64(self.auctionStartTime+self.auctionLength),
                minNextBid: self.minNextBid(),
                completed: self.auctionCompleted,
                expired: self.isAuctionExpired()
            )
        }
        init (
            NFT_ID : UInt256, 
            NFT: @KittyItems.NFT?, 
            startPrice: UFix64,  
            auctionStartTime: UFix64, 
            minimumBidIncrement: UFix64, 
            auctionLength: UFix64, 
            ownerCollectionCap: Capability<&KittyItems.Collection>, 
            ownerVaultCap: Capability<&Kibble.Vault>, 
            curatorFeePercentage : UInt64
        ) {
            self.numberOfBids = (0 as UInt64)
            self.NFT_ID = NFT_ID 
            self.NFT <- NFT
            Auction.totalAuctions = Auction.totalAuctions + (1 as UInt64)
            self.auctionID = Auction.totalAuctions
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLength = auctionLength
            self.startPrice = startPrice
            self.currentPrice = 0.0
            self.auctionStartTime = auctionStartTime
            self.auctionCompleted = false
            self.recipientCollectionCap = nil
            self.recipientVaultCap = nil
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
            self.curatorFeePercentage = curatorFeePercentage
        }
    }


    pub resource Curator {

        pub let CuratorAddress : Address?
        pub let CuratorID : UInt64
        pub var totalNFTs : UInt64

        // To store bidding amount during each bid
        pub var bidVault : @Kibble.Vault
        
        // To store Curator's earned money after the auction
        pub var curatorVault : @Kibble.Vault

        // To store the NFTs for Auction
        pub var NFTCollection : @KittyItems.Collection

        // Checks basic conditions and then calls startAuction()
        pub fun approveAuction (
            NFT : @KittyItems.NFT, 
            ownerAddress: Address?, 
            startTime : Fix64, 
            endTime : Fix64
        ) : bool {
            if (startTime < endTime && ownerAddress) {
                AuctionStatus.approved = true;
                AuctionStatus.itemOwner = ownerAddress
                self.startAuction(token: <- NFT, ownerAddress: Address?, startTime : Fix64, endTime : Fix64)
                return true;
            }
            else {
                // self.cancelAuction(auctionID: UInt256, token: <- NFT, ownerAddress: Address?);
                return false;
            }
        }

        pub fun startAuction (
            NFT : @KittyItems.NFT, 
            ownerAddress: Address?, 
            startTime : Fix64, 
            endTime : Fix64
        ) : bool {
            self.totalNFTs = self.totalNFTs + (1 as UInt64)
            pub let NFT_ID = self.totalNFTs
            self.NFTCollection.deposit(token: <- NFT)
            pub var newAuction <- createNewAuction (
                NFT_ID : UInt64, 
                ownerAddress: Address, 
                startTime : Fix64, 
                endTime : Fix64
            )
        }

        // Doubt : the withdrawn NFT is returned, but not stored in the owner's NFTCollection
        pub fun cancelAuction (
            auctionID: UInt256, 
            NFT_ID: UInt64, 
            ownerAddress: Address?
        ) : @KittyItems.NFT {
            self.totalNFTs = self.totalNFTs - (1 as UInt64)
            AuctionStatus.timeRemaining = (0 as Fix64)
            AuctionStatus.active = false
            AuctionStatus.cancelled = true
            AuctionStatus.expired = true
            totalAuctions = totalAuctions - (1 as UInt64)
            return <- self.KittyItems.NFT.withdraw(NFT_ID)
        }

        //Write this function later - It will deposit the curatorFee to curatorVault and do final changes
        pub fun endCompletedAuction (
            bidderAddress: Address?, 
            ownerAddress: Address?, 
            curatorFee: UInt256, 
            CuratorAddress: Address?, 
            curatorId: UInt64
        ) {
            self.curatorVault.deposit(curatorFee)
            self.itemOwner = bidderAddress
        }

        // sendNFT sends the NFT to the Collection belonging to the provided Capability
        pub fun sendNFT(capability: Capability<&{NonFungibleToken.CollectionPublic}>) {
            // borrow a reference to the owner's NFT receiver
            if let collectionRef = capability.borrow() {
                let NFT <- self.withdrawNFT()
                // deposit the token into the owner's collection
                collectionRef.deposit(token: <-NFT)
            } else {
                log(" unable to borrow collection ref")   
            }
        }

        // sendBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
        pub fun refundBid(capability: Capability<&{FungibleToken.Receiver}>) {
            // borrow a reference to the owner's NFT receiver
            if let vaultRef = capability.borrow() {
                let bidVaultRef = &self.bidVault as &FungibleToken.Vault
                vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
            } else {
                    log("sendBidTokens(): couldn't get vault ref")    
            }
        }

        init (
            CuratorAddress : Address?, 
            CuratorID : UInt64
        ) {
            self.CuratorAddress = CuratorAddress
            self.CuratorID = CuratorID
            self.totalNFTs = (0 as UInt64)
            self.bidVault <- Kibble.createEmptyVault()
            self.curatorVault <- Kibble.createEmptyVault()
            self.NFTCollection <- KittyItems.createEmptyCollection()
        }

        destroy () {
            log("destroy auction")
            // send the NFT back to auction owner
            // if there's a bidder...
            destroy self.bidVault
        }
    }


    pub fun createNewAuction (
        NFT_ID : UInt64, 
        ownerAddress: Address?, 
        startTime : Fix64, 
        endTime : Fix64
    ) {
        return <- AuctionItem (
            NFT_ID : UInt64, 
            ownerAddress: Address?, 
            startTime : Fix64, 
            endTime : Fix64
        )
    }

    init () {
        self.totalAuctions = (0 as UInt64)
    }
}