// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Libraries/LibGame.sol";

abstract contract gameStorage {
    uint256 public gameId;
    uint8 public CompetitorsLimit;

    enum gameState {
        SCEDULED,
        STARTED,
        RUNNING,
        FINISHED
    }

    struct gameDetail {
        address currency;
        address gameOwner;
        uint256 gameCreationTime;
        uint256 price;
        bool addBidders;
        uint256 bidStartTime;
        uint256 bidEndTime;
        bool winnerDecided;
        gameState state;
    }
    struct BidOrder {
        address currency;
        address userAddress;
        uint256 BidAmount;
        bool withdrawn;
    }
    // gameId => competitorIndex => BidOrder[]
    mapping(uint256 => mapping(uint8 => BidOrder[])) public Bids;
    /*
        BidIndex will always be plus one to actual Bid Index
        because if user will again bid then his Bids[_gameId][_competitorIndex][bidIndex - 1].BidAmount will only change
    */
    // userAddress => gameId => BidIndex
    mapping(address => mapping(uint256 => uint256)) public userBidIndex;
    // gameId => gameDetail
    mapping(uint256 => gameDetail) public gamesDetail;
    // gameId => Bidders Address
    mapping(uint256 => address[]) public Bidders;
    // gameId => (Bidder Address => Bidder Address index)
    mapping(uint256 => mapping(address => uint256)) public bidderAddressIndex;
    // gameId => LibGame.Competitor[]
    mapping(uint256 => LibGame.Competitor[]) public Competitors;
    // gameId => CompetitorIndex
    mapping(uint256 => uint8[]) public Winners;
    // gameId => CompetitorIndex => totalBidAmount
    mapping(uint256 => mapping(uint8 => uint256)) public totalBidAmount;
    // wolletAddress => Currency => Amount
    mapping(address => mapping(address => uint256)) private userWollet;
}
