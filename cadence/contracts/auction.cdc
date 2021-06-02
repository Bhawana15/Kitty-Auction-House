import Kibble from "./Kibble.cdc"
import KittyItems from "./KittyItems.cdc"

pub contract Auction {
    pub resource Curator {
        pub var CuratorID : UInt256
        pub var escrow : @Auction.Escrow
        pub var CuratorVault : @Kibble.Vault
        
        pub fun withdraw (ItemID : UInt64) : @KittyItems {
            self.escrow.numOfItems = self.escrow.numOfItems - 1
        }

        pub fun deposit (Item : @KittyItems) {
            self.numOfItems = self.numOfItems + 1
        }

        pub fun approveAuction () : bool {
            // Checks basic conditions and then calls startAuction()
        }

        pub fun startAuction () : bool {
            // calls Cutator.deposit()
        }

        pub fun cancelAuction () : @KittyItems {
            // calss Curator.withdraw() and returns the KittyItem
        }

        init (CuratorID : UInt256, CuratorVault : @Kibble.Vault) {
            self.escrow <- create Escrow()
            self.CuratorID = CuratorID
            self.CuratorVault <- CuratorVault
        }

        destroy () {
            destroy self.escrow
        }
    }

    pub resource Escrow {
        pub var CuratorID : UInt64
        pub var escrowDict : @{UInt64 : KittyItem}
        pub var numOfItems : UInt64
    }

    pub resource Bidders {
        pub var BidderID : UInt64
        pub var BidderKibbleVault : @Kibble.Vault
        pub var BidderKittyItemCollection : @KittyItems.Collection
        pub var BiddingAmount : UInt64
        pub var NumOfBids : UInt64

        pub fun createBid (auctionID : UInt256, BiddingAmount : UInt64) : UInt64 {
            /*NumOfBids = NumOfBids + 1
            self.BiddingAmount = BiddingAmount; */
        }
    }

    pub resource auction {
        pub var auctionID : UInt256
        pub var duration : UInt256
        pub var auctionStatus : AuctionStatus

        pub fun endAuction () {}
        pub fun createAuction () {}
        pub fun cancelAuction () {}
        pub fun setAuction () {}
    }

    pub struct AuctionStatus {
        pub var auctionApproved : bool
        pub var auctionCancelled : bool
        pub var recentBidderID : UInt256
        pub var recentBidAmount : UInt256
        pub var auctionEnded : bool
        pub var winner : UInt256
    }

    pub resource AuctionItem {
        pub var itemID : UInt256
        pub var reservePrice : UInt256
    }

    pub fun createCurator () : @Curator {}
    pub fun createEscrow() : @Escrow {}
    pub fun createBidder() : @Bidder {}
}