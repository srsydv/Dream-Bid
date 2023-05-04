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
    
    // gameId => gameDetail
    mapping(uint256 => gameDetail) public gamesDetail;
    // gameId => Bidders Address
    mapping(uint256 => address[]) public Bidders;
    // gameId => (Bidder Address => Bidder Address index)
    mapping(uint256 => mapping(address => uint256)) public bidderAddressIndex;
    // gameId => LibGame.Competitor[]
    mapping(uint256 => LibGame.Competitor[]) public Competitors;
    
    // wolletAddress => Currency => Amount
    mapping(address => mapping(address => uint256)) private userWollet;
}
