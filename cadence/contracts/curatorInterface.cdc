import Kibble from "./kitty-items/cadence/contracts/Kibble.cdc"
import KittyItems from "./kitty-items/cadence/contracts/KittyItems.cdc"

pub contract interface Actors {
    pub resource Curator {
        pub var CuratorID : UInt64
        pub var escrow : @Escrow
        pub var CuratorVault : @Kibble.Vault
        
        pub fun withdraw (ItemID : UInt64) : @KittyItems {
            escrow.numOfItems = escrow.numOfItems - 1
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

        init (escrow : @Escrow) {
            self.escrow <- createEscrow ()
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

    pub fun createCurator () : @Curator {}
    pub fun createEscrow() : @Escrow {}
    pub fun createBidder() : @Bidder {}
}