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

        /* 
        pub fun withdrawFromEscrow (ItemID : UInt64) : @KittyItems.Collection {
        }
        pub fun depositToEscrow (Item : @KittyItems.Collection) {
            self.numOfItems = self.numOfItems + 1
        }
        pub fun approveAuction () : bool {
            // Checks basic conditions and then calls startAuction()
        }
        pub fun startAuction () : bool {
            // calls Cutator.deposit()
        }
        pub fun cancelAuction () : @KittyItems.Collection {
            // calss Curator.withdraw() and returns the KittyItem
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

        init (NFT: @KittyItems.NFT?, reservePrice: UFix64, auctionStartTime: UFix64, minimumBidIncrement: UFix64, 
        duration: UFix64, ownerCollectionCap: Capability<&KittyItems.Collection>, 
        ownerVaultCap: Capability<&Kibble.Vault>) {
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
            //self.auctionStatus = {}
        }

        pub fun isAuctionExpired(): Bool {
            return AuctionStatus.active
        }

        pub fun minNextBid() :UFix64 {
            return AuctionItem.minBidIncrement
        }

        pub fun extendWith(_ amount: UFix64) {
            AuctionItem.duration = AuctionItem.duration + amount
        }

        pub fun timeRemaining() : Fix64 {
            return 
        }

        /*
        access(contract) fun sendNFT(_ capability: Capability<&{KittyItems.KittyItemsCollectionPublic}>)
        access(contract) fun sendBidTokens(_ capability: Capability<&{FungibleToken.Receiver}>)
        pub fun releasePreviousBid()
        pub fun settleAuction(cutPercentage: UFix64, cutVault:Capability<&{FungibleToken.Receiver}> )
        pub fun returnAuctionItemToOwner()
        
        pub fun bidder() : Address?
        pub fun currentBidForUser(address:Address): UFix64
        pub fun placeBid(bidTokens: @FungibleToken.Vault, vaultCap: Capability<&{FungibleToken.Receiver}>, 
        collectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>)
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