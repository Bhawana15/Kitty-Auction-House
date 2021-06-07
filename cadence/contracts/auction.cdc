import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import Kibble from "./Kibble.cdc"
import KittyItems from "./KittyItems.cdc"

pub contract Auction {
    pub var totalAuctions : UInt64

    // EVENTS : WRITE HERE

    pub resource Curator {
        pub let CuratorAddress : Address?
        pub let CuratorID : UInt64
        pub let CuratorVaultCap : Capability<&Kibble.Vault{FungibleToken.Receiver}>?
        pub var escrow : {UInt64 : UInt64}

        pub fun approveAuction () {
            // Checks basic conditions and then calls startAuction()
            AuctionStatus.approved = true;
            self.startAuction()
        }

        pub fun startAuction () : bool {
            // calls Cutator.deposit()
            AuctionItem.numberOfBids = 0
            self.deposit()
        }

        pub fun cancelAuction () : @KittyItems.Collection {
            // calss Curator.withdraw() and returns the KittyItem
            self.withdraw()
        }

        /* 
        pub fun withdrawFromEscrow (ItemID : UInt64) : @KittyItems.Collection {
        }
        pub fun depositToEscrow (Item : @KittyItems.Collection) {
            self.numOfItems = self.numOfItems + 1
        }
        */

        init (CuratorAddress : Address?, CuratorID : UInt64) {
            self.CuratorAddress = CuratorAddress
            self.CuratorID = CuratorID
            self.escrow = {}
            self.CuratorVaultCap = nil
        }
    }

    pub resource AuctionItem {
        pub var tokenID : UInt256
        access(self) var numberOfBids: UInt64
        access(self) var NFT: @KittyItems.NFT?
        pub let auctionID : UInt64
        access(self) let minimumBidIncrement: UFix64
        access(account) var reservePrice : UFix64
        access(self) var auctionStartTime: UFix64
        access(self) var duration : UFix64
        // pub var auctionStatus : AuctionStatus
        access(self) var auctionCompleted: Bool
        access(self) var currentPrice: UFix64
        access(self) var recipientCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>?
        access(self) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?
        access(self) let ownerCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>
        access(self) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
        pub var curatorFeePercentage : UInt64
        pub var curatorAdd : Address

        init (NFT: @KittyItems.NFT?, reservePrice: UFix64, auctionStartTime: UFix64, minimumBidIncrement: UFix64, 
        duration: UFix64, ownerCollectionCap: Capability<&KittyItems.Collection>, 
        ownerVaultCap: Capability<&Kibble.Vault>, curatorFeePercentage : uint8) {
            self.numberOfBids = (0 as UInt64) 
            self.NFT <- NFT
            Auction.totalAuctions = Auction.totalAuctions + (1 as UInt64)
            self.auctionID = Auction.totalAuctions
            self.minimumBidIncrement = minimumBidIncrement
            self.duration = duration
            self.reservePrice = reservePrice
            self.currentPrice = 0.0
            self.auctionStartTime = auctionStartTime
            self.auctionCompleted = false
            self.recipientCollectionCap = nil
            self.recipientVaultCap = nil
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
            self.curatorFeePercentage = curatorFeePercentage
            //self.auctionStatus = {}
        }

        pub fun isAuctionExpired() : Bool {
            return !AuctionStatus.active
        }

        pub fun minNextBid() :UFix64 {
            return AuctionItem.minBidIncrement
        }

        pub fun extendWith(_ amount: UFix64) {
            AuctionItem.duration = AuctionItem.duration + amount
        }

        pub fun timeRemaining() : Fix64 {
            return Fix64(self.duration) - Fix64(getCurrentBlock.timestamp())
        }

        pub fun bidder() : Address? {
            if let vaultCap = self.recipientVaultCap {
                return vaultCap.borrow()!.owner!.address
            }
            return nil
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(id: UInt64, bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>,  
        collectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>) {
            pre {
                self.auctionItems[id] != nil:
                "Auction does not exist in this drop"
        }

        // Get the auction item resources
        let itemRef = &self.auctionItems[id] as &AuctionItem
        itemRef.placeBid(bidTokens: <- bidTokens, 
        vaultCap:vaultCap, 
        collectionCap:collectionCap)
    }

        /*
        access(contract) fun sendNFT(_ capability: Capability<&{KittyItems.KittyItemsCollectionPublic}>)
        access(contract) fun sendBidTokens(_ capability: Capability<&{FungibleToken.Receiver}>)
        pub fun releasePreviousBid()
        pub fun settleAuction(cutPercentage: UFix64, cutVault:Capability<&{FungibleToken.Receiver}> )
        pub fun returnAuctionItemToOwner()
        pub fun currentBidForUser(address:Address): UFix64
        pub fun getAuctionStatus() : AuctionStatus
        */

        pub fun endAuction () {}
        pub fun createAuction () {}
        pub fun cancelAuction () {}
        pub fun setAuction () {}

        destroy () {
            destroy self.NFT
        }
    }

    pub struct AuctionStatus {
        pub let itemOwner: Address?
        pub var auctionID : UInt256 
        pub let startTime : Fix64
        pub let endTime : Fix64
        pub let timeRemaining : Fix64
        pub let bidIncrement : UFix64
        pub let minBidIncrement : UInt64
        pub var recentBidderID : UInt256
        pub var recentBidAmount : UInt256
        pub var active : Bool
        pub var approved : Bool
        pub var cancelled : Bool
        pub var expired: Bool

        init(itemOwner : Address?, auctionID : UInt256, bidIncrement : UFix64, timeRemaining : Fix64, endTime : Fix64, 
        startTime : Fix64, recentBidderID : UInt256, recentBidAmount : UInt256, minBidIncrement : UInt64) {
            self.itemOwner = itemOwner
            self.auctionID = auctionID
            self.bidIncrement = bidIncrement
            self.minBidIncrement = minBidIncrement
            self.timeRemaining = timeRemaining
            self.endTime = endTime
            self.startTime = startTime
            self.recentBidderID = recentBidderID
            self.recentBidAmount = recentBidAmount
            self.approved = false
            self.cancelled = false
            self.active = false
            self.expired = false
        }
    }

    init () {
        self.totalAuctions = (0 as UInt64)
    }

    pub fun createAuction (token: @KittyItems.NFT, minimumBidIncrement: UFix64, duration: UFix64, auctionStartTime: UFix64,
    startPrice: UFix64, collectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>, 
    vaultCap: Capability<&{FungibleToken.Receiver}>) {

        // create a new auction items resource container
            let item <- Auction.createStandaloneAuction(
                token: <-token,
                minimumBidIncrement: minimumBidIncrement,
                auctionLength: auctionLength,
                auctionStartTime: auctionStartTime,
                startPrice: startPrice,
                collectionCap: collectionCap,
                vaultCap: vaultCap
            )

            let id = item.auctionID

            // update the auction items dictionary with the new resources
            let oldItem <- self.auctionItems[id] <- item
            destroy oldItem

            let owner= vaultCap.borrow()!.owner!.address
            // emit Created(tokenID: id, owner: owner, startPrice: startPrice, startTime: auctionStartTime)

    }

    //this method is used to create a standalone auction that is not part of a collection
    //we use this to create the unique part of the Versus contract
    pub fun createStandaloneAuction(
        token: @KittyItems.NFT, 
        minimumBidIncrement: UFix64, 
        auctionLength: UFix64,
        auctionStartTime: UFix64,
        startPrice: UFix64, 
        collectionCap: Capability<&{Art.CollectionPublic}>, 
        vaultCap: Capability<&{FungibleToken.Receiver}>) : @AuctionItem {
            
        // create a new auction items resource container
        return  <- create AuctionItem(
            NFT: <-token,
            minimumBidIncrement: minimumBidIncrement,
            auctionStartTime: auctionStartTime,
            startPrice: startPrice,
            auctionLength: auctionLength,
            ownerCollectionCap: collectionCap,
            ownerVaultCap: vaultCap
        )
    }
}

// pub fun createBidder() : @Bidder {}
    /* 
    pub resource Bidders {
        pub var BidderID : UInt256
        pub let BidderVaultCap : Capability<&Kibble.Vault>?
        //pub var BidderKittyItemCollection : @KittyItems.Collection
        pub var BiddingAmount : UInt256

        /* NumOfBids = NumOfBids + 1, self.BiddingAmount = BiddingAmount; */
        pub fun createBid (auctionID : UInt256, BiddingAmount : UInt64) : UInt256 {
            return self.BiddingAmount
        }

        init (BidderID : UInt256, BiddingAmount : UInt256) {
            self.BidderID = BidderID
            self.BidderVaultCap = nil
            // self.BidderKittyItemCollection <- BidderKittyItemCollection
            self.BiddingAmount = BiddingAmount
        }

        destroy () {
            destroy self.BidderKibbleVault
            destroy self.BidderKittyItemCollection
        }
    } */