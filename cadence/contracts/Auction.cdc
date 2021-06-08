import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import Kibble from "./Kibble.cdc"
import KittyItems from "./KittyItems.cdc"

pub contract Auction {
    pub var totalAuctions : UInt64

    // EVENTS : WRITE HERE
    // event newAuctionCreated (auctionID, NFT_ID, Curator_ID, ownerAddress)
    // event auctionEnded(auctionID, NFT_ID, Curator_ID, oldOwnerAddress, winnerAddress)
    // event auctionCancelled(auctionID, NFT_ID, Curator_ID, ownerAddress)

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

    pub resource AuctionItem {
        pub var tokenID : UInt256
        access(self) var numberOfBids: UInt64
        access(self) var NFT: @KittyItems.NFT?
        pub let auctionID : UInt64
        access(self) let minimumBidIncrement: UFix64
        access(account) var reservePrice : UFix64
        access(self) var auctionStartTime: UFix64
        access(self) var duration : UFix64
        pub var auctionStatus : AuctionStatus
        access(self) var auctionCompleted: Bool
        access(self) var currentPrice: UFix64
        access(self) var recipientCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>?
        access(self) var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?
        access(self) let ownerCollectionCap: Capability<&{KittyItems.KittyItemsCollectionPublic}>
        access(self) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
        pub var curatorFeePercentage : UInt64
        pub var curatorAdd : Address

        pub fun isAuctionExpired() : Bool {
            return !AuctionStatus.active
        }

        pub fun minNextBid() :UFix64 {
            return AuctionItem.minBidIncrement
        }

        pub fun extendWith(_ amount: UFix64) {
            AuctionStatus.timeRemaining = AuctionStatus.timeRemaining + amount
            AuctionItem.duration = AuctionItem.duration + amount
        }

        pub fun timeRemaining() : Fix64 {
            return Fix64(self.duration) - Fix64(getCurrentBlock.timestamp())
        }

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
            self.auctionStatus = AuctionStatus()
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
        pub fun approveAuction (NFT : @KittyItems.NFT, ownerAddress: Address?, startTime : Fix64, endTime : Fix64) : bool {
                if (startTime < endTime && ownerAddress) {
                    AuctionStatus.approved = true;
                    AuctionStatus.itemOwner = ownerAddress
                    self.startAuction(token: <- NFT, ownerAddress: Address?, startTime : Fix64, endTime : Fix64)
                    return true;
                }
                else {
                    self.cancelAuction(auctionID: UInt256, (token: <- NFT, ownerAddress: Address?);
                    return false;
                }
        }

        pub fun startAuction (NFT : @KittyItems.NFT, ownerAddress: Address?, startTime : Fix64, endTime : Fix64) : bool {
            self.totalNFTs = self.totalNFTs + (1 as UInt64)
            pub let NFT_ID = self.totalNFTs
            self.NFTCollection.deposit(token: <- NFT)
            pub var newAuction <- createNewAuction (
                NFT_ID : UInt64, 
                ownerAddress: Address?, 
                startTime : Fix64, 
                endTime : Fix64)
        }

        // Doubt : the withdrawn NFT is returned, but not stored in the owner's NFTCollection
        pub fun cancelAuction (auctionID: UInt256, NFT_ID: UInt64, ownerAddress: Address?) : @KittyItems.NFT {
            self.totalNFTs = self.totalNFTs - (1 as UInt64)
            AuctionStatus.timeRemaining = (0 as Fix64)
            AuctionStatus.active = false
            AuctionStatus.cancelled = true
            AuctionStatus.expired = true
            totalAuctions = totalAuctions - (1 as UInt64)
            return <- self.NFTCollection.withdraw(NFT_ID)
        }

        //Write this function later - It will deposit the curatorFee to curatorVault and do final changes
        pub fun endCompletedAuction (bidderAddress: Address?, ownerAddress: Address?, curatorFee: UInt256, 
        CuratorAddress: Address?, curatorId: UInt64) {
            self.curatorVault.deposit(curatorFee)
            self.itemOwner = bidderAddress
        }

        init (CuratorAddress : Address?, CuratorID : UInt64) {
            self.CuratorAddress = CuratorAddress
            self.CuratorID = CuratorID
            self.totalNFTs = (0 as UInt64)
            self.bidVault <- Kibble.createEmptyVault()
            self.curatorVault <- Kibble.createEmptyVault()
            self.NFTCollection <- KittyItems.createEmptyCollection()
        }
    }

    pub fun createNewAuction (NFT_ID : UInt64, ownerAddress: Address?, startTime : Fix64, endTime : Fix64) {
        return <- AuctionItem (NFT_ID : UInt64, ownerAddress: Address?, startTime : Fix64, endTime : Fix64)
    }

    init () {
        self.totalAuctions = (0 as UInt64)
    }
}