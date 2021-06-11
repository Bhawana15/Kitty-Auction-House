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
        pub let curatorPercent: UFix64 // doubt
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

        // It returns the bid tokens from Curator's bidValut to the provided capability as previous bid is cancelled
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

        // Sends NFT token from Curator's NFTCollection to the provided Collection capability
        pub fun sendNFT(collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>) {
            // borrow a reference to the owner's NFT receiver
            if let bidderCollectionRef = bidderCollectionCap.borrow() {
                let NFT <- self.withdrawNFT()
                // deposit the token into the owner's collection
                collectionRef.deposit(token: <-NFT)
            } else {
                log("Unable to borrow collection ref")   
            }
        }

        // Withdraws NFT from Curator.NFT Collection
        pub fun withdrawNFT(): @NonFungibleToken.NFT {
            let NFT <- self.NFTCollection.withdraw() <- nil
            return <- NFT!
        }

        // Ends the auction that has been completed by calling AuctionItem.settleAuction()
        pub fun endCompletedAuction() {   
           AuctionItem.settleAuction(cutPercent : self.curatorPercent)

            emit auction_ended_and_settled (auctionID: UInt64, tokenID: UInt64, curatorID: UInt64, 
                oldOwnerAddress: Address, winnerAddress: Address)
        }

        // Cancels auction and returns NFT from Curator to Owner and bid amount from bbidVault to bidder
        pub fun cancelAuction (
            auctionID: UInt256, 
            tokenID: UInt64, 
            ownerAddress: Address?
        ) : @KittyItems.NFT {
            self.totalNFTs = self.totalNFTs - (1 as UInt64)
            self.totalAuctions = self.totalAuctions - (1 as UInt64)
        
            // deposit the NFT into the owner's collection
            self.sendNFT(self.ownerCollectionCap)

            self.returnBidTokens(self.ownerVaultCap)
            // AuctionItem.destroy()

            emit auction_cancelled (auctionID: UInt64, tokenID: UInt64, curatorID: UInt64, ownerAddress: Address)

            return <- self.KittyItems.NFT.withdraw(tokenID)
        }

        init (
            curatorAddress : Address?, 
            curatorPercent : UFix64
        ) {
            self.curatorAddress = curatorAddress
            Auction.totalCurators = Auction.totalCurators + (1 as UInt64)
            self.curatorID = Auction.totalCurators
            self.curatorPercent = curatorPercent
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

        // Returns the minimum bid amount that should be placed for next bid
        pub fun minNextBid () : UFix64 {
            if self.currentBidForUser () == 0.0 {
                return self.startPrice
            }
            return AuctionItem.minimumBidIncrement + self.currentPrice
        }

        // Returns NFT to the Owner if Auction is cancelled
        pub fun returnAuctionItemToOwner() {
            // release the bidder's tokens
            self.releasePreviousBid() //////// doubt

            // deposit the NFT into the owner's collection
            Curator.sendNFT(self.ownerCollectionCap)
        }

        // Returns the bid amount from the Bidder to the Curator
        pub fun releasePreviousBid() {
            if let vaultCap = self.recipientVaultCap {
                Curator.returnBidTokens(self.recipientVaultCap!)
                return
            } 
        }
        
        // Places a new bid during the Auction. 
        // Calls returnBidTokens() which returns the bid tokens from Curator to the provided capability as previous bid 
        // is cancelled. Deposits the new bid amount from new bidder’s bid vault to the Curator’s bid vault.
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

        // Settles the auction 
        /* Withdraws curatorPercent amount from Curator.bidVault and transfers it to Curator.curatorVault.
        Also calls Curator.sendNFT() which Sends NFT token from Curator's NFTCollection to the provided Collection 
        capability by calling Curator.withdrawNFT() which returns NFT from Curator’s NFTCollection */
        pub fun settleAuction(cutPercentage: UFix64)  {

            pre {
                !self.auctionCompleted : "The auction is already settled"
                self.NFT != nil: "NFT in auction does not exist"
                self.isAuctionExpired() : "Auction has not completed yet"
            }

            // return if there are no bids to settle
            if self.currentPrice == 0.0{
                self.returnAuctionItemToOwner() // we dont have owner, we have curator
                return
            }

            let bidVaultRef = &Curator.bidVault as &kibble.Vault
            let curatorVaultRef = &Curator.curatorVault as &kibble.Vault

            //Withdraw cutPercentage to marketplace and put it in their vault
            let amount = self.currentPrice * cutPercentage / 100
            let beneficiaryCut <- bidVaultRef.withdraw(amount:amount )

            curatorVaultRef.deposit(from: <- beneficiaryCut)

            Curator.sendNFT(self.recipientCollectionCap!)
            Curator.returnBidTokens(self.ownerVaultCap) // it should not be here

            self.auctionCompleted = true
            
            emit auctionSettled(tokenID: self.auctionID, price: self.currentPrice)
        }

        // Returns whether auction is expired or not
        pub fun isAuctionExpired() : Bool {
            let timeRemaining= self.timeRemaining()
            return AuctionItem.timeRemaining() < Fix64(0.0)
        }

        // 
        pub fun timeRemaining() : Fix64 {
            return Fix64(self.auctionLength) - Fix64(getCurrentBlock.timestamp())
        }

        // Returns the status of this Auction
        pub fun getAuctionStatus() :AuctionStatus {

            return AuctionStatus(
                tokenID: self.tokenID, 
                auctionID: self.auctionID,
                currentPrice: self.currentPrice, 
                minimumBidIncrement: self.minimumBidIncrement, 
                timeRemaining: self.timeRemaining(), 
                active: !self.auctionCompleted  && !self.isAuctionExpired(), 
                completed: self.auctionCompleted, 
                startTime: Fix64(self.startTime),
                endTime: Fix64(self.startTime+self.auctionLength),
                minNextBid: self.minNextBid(),
                expired: self.isAuctionExpired()
            )
        }
        
        init (
            tokenID : UInt256, 
            startPrice: UFix64,  
            startTime: UFix64, 
            minimumBidIncrement: UFix64, 
            auctionLength: UFix64, 
            ownerCollectionCap: Capability<&KittyItems.Collection>, 
            ownerVaultCap: Capability<&Kibble.Vault>, 
            curatorFeePercentage : UInt64
        ) {
            self.numberOfBids = (0 as UInt64)
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

    pub struct AuctionStatus {
        pub let tokenID: UInt64?
        pub var auctionID : UInt64
        pub let currentPrice : UFix64 
        pub let minimumBidIncrement : UFix64
        pub let timeRemaining : Fix64
        pub var active : Bool
        pub var completed: Bool 
        pub let startTime : Fix64
        pub let endTime : Fix64

        init(
            tokenID: UInt64?, 
            auctionID : UInt64,
            currentPrice : UFix64,  
            minimumBidIncrement : UFix64, 
            timeRemaining : Fix64, 
            endTime : Fix64, 
            startTime : Fix64, 
        ) {
            self.tokenID = tokenID
            self.auctionID = auctionID
            self.currentPrice = currentPrice
            self.minimumBidIncrement = minimumBidIncrement
            self.timeRemaining = timeRemaining
            self.endTime = endTime
            self.startTime = startTime
            self.active = false
            self.completed = false
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
    pub fun createNewCurator () : @Curator {
        return <- create Curator(curatorAddress : Address, curatorPercent : UFix64)
    }
    
    init () {
        self.totalAuctions = (0 as UInt64)
        self.totalCurators = (0 as UInt64)
    }
}