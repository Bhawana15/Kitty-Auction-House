// WHAT IS LEFT:
// Functions : Curator.cancelAuction(), Curator.endCompletedAuction(), Curator.sendNFT(), Curator.returnBidTokens()
//             AuctionItem.settleAuction(), Auction.createNewCurator()
// Variable : AuctionStatus.leader
// Events : Check again

import FungibleToken from 0x4fc019cea9fc4817
import NonFungibleToken from 0x4fc019cea9fc4817
import Kibble from 0x4fc019cea9fc4817
import KittyItems from 0x4fc019cea9fc4817


pub contract Auction {
    
    pub var totalAuctions : UInt64
    pub var totalCurators : UInt64

    // EVENTS
    pub event auction_request_approved (tokenID: UInt64, owner: Address, startPrice: UFix64, startTime: UFix64)
    pub event auction_created_and_started (tokenID: UInt64, owner: Address, startPrice: UFix64, startTime: UFix64)
    pub event auction_ended_and_settled (auctionID: UInt64, tokenID: UInt64, curatorID: UInt64, 
        oldOwnerAddress: Address, winnerAddress: Address)
    pub event auction_cancelled (auctionID: UInt64, tokenID: UInt64, curatorID: UInt64, ownerAddress: Address)
    pub event new_bid_placed(tokenID: self.auctionID, bidderAddress: bidderAddress, bidPrice: self.currentPrice)


    pub resource Curator {

        pub let curatorAddress : Address?
        pub let curatorID : UInt64
        pub var totalNFTs : UInt64

        // To store bidding amount during each bid
        pub var bidVault : @Kibble.Vault
        
        // To store Curator's earned money after the auction
        pub var curatorVault : @Kibble.Vault

        // To store the NFTs for Auction
        pub var NFTCollection : @KittyItems.Collection

        access(self) let ownerCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>
        access(self) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>

        // Checks basic conditions to approve the auction
        pub fun approveAuction (
            ownerCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>, 
            ownerAddress: Address?,
            tokenID : UInt64, 
            startTime : Fix64, 
            endTime : Fix64
        ) : bool {
            self.ownerCollectionCap = ownerCollectionCap
            let ownerCollection = self.ownerCollectionCap.borrow()
            if (startTime < endTime && ownerAddress && ownerCollection.ownedNFTs[tokenID] != nil) {
                emit auction_request_approved (tokenID: UInt64, owner: Address, startPrice: UFix64, startTime: UFix64)

                return true
            }
            return false
        }

        pub fun startAuction (
            ownerCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>, 
            tokenID : UInt64, 
            ownerAddress: Address?, 
            startTime : Fix64, 
            endTime : Fix64
        ) {
            self.totalNFTs = self.totalNFTs + (1 as UInt64)
            self.tokenID = tokenID
            let token <- self.ownerCollectionCap.borrow().ownedNFTs[ID]
            self.NFTCollection.deposit(token: <- token)
            pub var newAuction <- createNewAuction (
                tokenID : UInt64, 
                ownerAddress: Address, 
                startTime : Fix64, 
                endTime : Fix64
            )

            emit auction_created_and_started (tokenID: UInt64, owner: Address, startPrice: UFix64, startTime: UFix64)
        }

        /* We dont need this bcoz at the end NFTCollection.withdraw ko call krna pdega
        pub fun withdrawNFT(): @NonFungibleToken.NFT {
            let NFT <- self.NFTCollection.withdraw() <- nil
            return <- NFT!
        }

        // Sends NFT token to the Bidder's NFT Collection
        pub fun sendNFT(bidderCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) {
            // borrow a reference to the owner's NFT receiver
            if let bidderCollectionRef = bidderCollectionCap.borrow() {
                let NFT <- self.withdrawNFT()
                // deposit the token into the owner's collection
                collectionRef.deposit(token: <-NFT)
            } else {
                log("Unable to borrow collection ref")   
            }
        }

        // returnBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
        pub fun refundBid(capability: Capability<&{FungibleToken.Receiver}>) {
            // borrow a reference to the owner's NFT receiver
            if let vaultRef = capability.borrow() {
                let bidVaultRef = &self.bidVault as &FungibleToken.Vault
                vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
            } else {
                    log("returnBidTokens(): couldn't get vault reference")    
            }
        }
        */

        //Write this function later - It will deposit the curatorFee to curatorVault and do final changes
        pub fun endCompletedAuction (
            bidderAddress: Address?, 
            ownerAddress: Address?, 
            curatorFee: UInt256, 
            curatorAddress: Address?, 
            curatorID: UInt64
        ) {
            self.curatorVault.deposit(curatorFee)
            self.itemOwner = bidderAddress

            emit auction_ended_and_settled (auctionID: UInt64, tokenID: UInt64, curatorID: UInt64, 
                oldOwnerAddress: Address, winnerAddress: Address)
        }

        // Doubt : the withdrawn NFT is returned, but not stored in the owner's NFTCollection
        pub fun cancelAuction (
            auctionID: UInt256, 
            tokenID: UInt64, 
            ownerAddress: Address?
        ) : @KittyItems.NFT {
            self.totalNFTs = self.totalNFTs - (1 as UInt64)
            AuctionStatus.timeRemaining = (0 as Fix64)
            AuctionStatus.active = false
            AuctionStatus.cancelled = true
            AuctionStatus.expired = true
            totalAuctions = totalAuctions - (1 as UInt64)

            emit auction_cancelled (auctionID: UInt64, tokenID: UInt64, curatorID: UInt64, ownerAddress: Address)

            return <- self.KittyItems.NFT.withdraw(tokenID)
        }

        init (
            curatorAddress : Address?, 
            curatorID : UInt64
        ) {
            self.curatorAddress = curatorAddress
            self.curatorID = curatorID
            self.totalNFTs = (0 as UInt64)
            self.bidVault <- Kibble.createEmptyVault()
            self.curatorVault <- Kibble.createEmptyVault()
            self.NFTCollection <- KittyItems.createEmptyCollection()
            self.ownerCollectionCap = nil
            self.ownerVaultCap = nil
        }

        destroy () {
            log("destroy auction")
            // send the NFT back to auction owner
            // if there's a bidder...
            destroy self.bidVault
        }
    }

    
    pub struct AuctionStatus {
        pub let itemOwner: Address?
        pub let tokenID: UInt64?
        pub var auctionID : UInt64
        pub let currentBidAmount : UFix64 
        pub let bidIncrement : UFix64
        pub let timeRemaining : Fix64
        pub var active : Bool
        pub var cancelled : Bool
        pub var completed: Bool 
        pub let startTime : Fix64
        pub let endTime : Fix64
        pub let minimumBidIncrement : UInt64
        // pub var recentBidderID : UInt256
        // pub let bids : UInt64 // 
        // pub let metadata: Art.Metadata?
        
        // pub let leader: Address?

        init(
            itemOwner : Address?, 
            tokenID: UInt64?, 
            auctionID : UInt64,
            currentBidAmount : UFix64,  
            bidIncrement : UFix64, 
            timeRemaining : Fix64, 
            endTime : Fix64, 
            startTime : Fix64, 
            minimumBidIncrement : UInt64
        ) {
            self.itemOwner = itemOwner
            self.tokenID = tokenID
            self.auctionID = auctionID
            self.currentBidAmount = currentBidAmount
            self.bidIncrement = bidIncrement
            self.timeRemaining = timeRemaining
            self.endTime = endTime
            self.startTime = startTime
            self.cancelled = false
            self.active = false
            self.completed = false
            self.minimumBidIncrement = minimumBidIncrement
        }
    }


    pub resource AuctionItem {

        pub var tokenID : UInt256
        access(self) var numberOfBids: UInt64
        pub let auctionID : UInt64
        access(self) let minimumBidIncrement: UFix64
        access(self) var startTime: UFix64
        access(self) var auctionLength : UFix64
        access(self) var auctionCompleted: Bool
        access(account) var startPrice: UFix64
        access(self) var currentPrice: UFix64 
        access(self) var recipientCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>?
        access(self) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?
        access(self) let curatorCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>
        access(self) let curatorVaultCap: Capability<&{FungibleToken.Receiver}>
        pub var curatorFeePercentage : UInt64
        
        // Returns address of the recent Bidder
        pub fun bidder () : Address? {
            if let vaultCap = self.recipientVaultCap {
                return vaultCap.borrow()!.owner!.address
            }
            return nil
        }

        // Returns the current Bid 
        pub fun currentBidForUser () : UFix64 {
            if self.currentPrice != 0.0 {
                return self.bidVault.balance
            }
            return 0.0   
        }

        // Returns the minimum amount of bid that can should be placed for a bidder
        pub fun minNextBid () : UFix64 {
            if self.currentBidForUser () == 0.0 {
                return self.startPrice
            }
            return AuctionItem.minimumBidIncrement + self.currentPrice
        }
        
        // returnBidTokens sends the bid tokens from Curator to the provided capability
        access(contract) fun returnBidTokens(_ toRecipientcap: Capability<&{FungibleToken.Receiver}>) {
            // borrow a reference to the owner's NFT receiver
            if let vaultRef = toRecipientcap.borrow() {
                let bidVaultRef = &self.bidVault as &FungibleToken.Vault
                if(bidVaultRef.balance > 0.0) {
                    vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
                }
                return
            }

            if let ownerRef= self.ownerVaultCap.borrow() {
                let bidVaultRef = &self.bidVault as &FungibleToken.Vault
                if(bidVaultRef.balance > 0.0) {
                    ownerRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
                }
                return
            }
        }
        
        // Places a new bid during the Auction. It also needs AuctionID
        pub fun placeBid (
            newBidderVault: @FungibleToken.Vault, 
            vaultCap: Capability<&{FungibleToken.Receiver}>, 
            collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
        ) {
            pre {
                !self.completed : "The auction is already settled"
                Curator.NFTCollection.ownedNFTs[self.tokenID] != nil: "NFT in auction does not exist"
            }

            let newBidderAddress = vaultCap.borrow()!.owner!.address

            let newBiddingAmount = newBidderVault.balance
            let minNextBid = self.minNextBid()
            if newBiddingAmount < minNextBid {
                panic("bid amount must be larger or equal to the current price + minimum bid increment "
                .concat(amountYouAreBidding.toString()).concat(" < ").concat(minNextBid.toString()))
             }

            if self.bidder() != newBidderAddress {
              if self.bidVault.balance != 0.0 {
                self.returnBidTokens(self.recipientVaultCap!)
              }
            }

            // Update the auction item
            Curator.bidVault.deposit(from: <-bidVault)

            //update the capability of the wallet for the address with the current highest bid
            self.recipientVaultCap = vaultCap

            // Update the current price of the token
            self.currentPrice = Curator.bidVault.balance

            // Add the bidder's Vault and NFT receiver references
            self.recipientCollectionCap = collectionCap
            self.numberOfBids=self.numberOfBids+(1 as UInt64)

            emit new_bid_placed (tokenID: self.auctionID, bidderAddress: bidderAddress, bidPrice: self.currentPrice)
        }

        // Returns the bid amount from the Bidder to the Curator
        pub fun releasePreviousBid() {
            if let vaultCap = self.recipientVaultCap {
                Curator.returnBidTokens(self.recipientVaultCap!)
                return
            } 
        }

        // Returns whether auction is expired or not
        pub fun isAuctionExpired() : Bool {
            let timeRemaining= self.timeRemaining()
            return AuctionItem.timeRemaining() < Fix64(0.0)
        }

        // It extends the Length of the Auction
        pub fun extendWith(_ amount: UFix64) {
            AuctionItem.auctionLength = AuctionItem.auctionLength + amount
        }

        // Returns the time remaining for the auction to get completed normally
        pub fun timeRemaining() : Fix64 {
            return Fix64(self.auctionLength) - Fix64(getCurrentBlock.timestamp())
        }

        // Returns the status of this Auction
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
                startTime: Fix64(self.startTime),
                endTime: Fix64(self.startTime+self.auctionLength),
                minNextBid: self.minNextBid(),
                completed: self.auctionCompleted,
                expired: self.isAuctionExpired()
            )
        }

        // Settles the auction 
        pub fun settleAuction(cutPercentage: UFix64, cutVault:Capability<&{FungibleToken.Receiver}> )  {

            pre {
                !self.auctionCompleted : "The auction is already settled"
                self.NFT != nil: "NFT in auction does not exist"
                self.isAuctionExpired() : "Auction has not completed yet"
            }

            // return if there are no bids to settle
            if self.currentPrice == 0.0{
                self.returnAuctionItemToOwner()
                return
            }            

            //Withdraw cutPercentage to marketplace and put it in their vault
            let amount = self.currentPrice * cutPercentage
            let beneficiaryCut <- self.bidVault.withdraw(amount:amount )

            let cutVault=cutVault.borrow()!
            emit MarketplaceEarned(amount: amount, owner: cutVault.owner!.address)
            cutVault.deposit(from: <- beneficiaryCut)

            self.sendNFT(self.recipientCollectionCap!)
            self.returnBidTokens(self.ownerVaultCap)

            self.auctionCompleted = true
            
            emit auctionSettled(tokenID: self.auctionID, price: self.currentPrice)
        }
        
        init (
            tokenID : UInt256, 
            NFT: @KittyItems.NFT?, 
            startPrice: UFix64,  
            startTime: UFix64, 
            minimumBidIncrement: UFix64, 
            auctionLength: UFix64, 
            ownerCollectionCap: Capability<&KittyItems.Collection>, 
            ownerVaultCap: Capability<&Kibble.Vault>, 
            curatorFeePercentage : UInt64
        ) {
            self.numberOfBids = (0 as UInt64)
            self.tokenID = tokenID 
            self.NFT <- NFT
            Auction.totalAuctions = Auction.totalAuctions + (1 as UInt64)
            self.auctionID = Auction.totalAuctions
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionLength = auctionLength
            self.startPrice = startPrice
            self.currentPrice = 0.0
            self.startTime = startTime
            self.auctionCompleted = false
            self.recipientCollectionCap = nil
            self.recipientVaultCap = nil
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
            self.curatorFeePercentage = curatorFeePercentage
        }
    }

    // Creates new auction
    pub fun createNewAuction (
        tokenID : UInt64, 
        ownerAddress: Address?, 
        startTime : Fix64, 
        endTime : Fix64
    ) {
        return <- AuctionItem (
            tokenID : UInt64, 
            ownerAddress: Address, 
            startTime : Fix64, 
            endTime : Fix64
        )
    }

    // Creates new Curator
    pub fun createCurator () : @Curator {

    }

    init () {
        self.totalAuctions = (0 as UInt64)
        self.totalCurators = (0 as UInt64)
    }
}