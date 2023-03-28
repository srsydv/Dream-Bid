// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Libraries/LibGame.sol";

abstract contract gameStorage {
    uint256 public gameId;

    enum gameState {
        SCEDULED,
        STARTED,
        RUNNING,
        FINISHED
    }

    struct gameDetail {
        address ERC20contract;
        address gameOwner;
        uint256 gameCreationTime;
        uint256 price;
        bool fixPrice;
        bool addBidders;
        uint256 bidStartTime;
        uint256 bidEndTime;
        gameState state;
    }

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
}
