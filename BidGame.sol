// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./gameStorage.sol";
import "./Libraries/LibGame.sol";
import "./gameRegistry.sol";

contract BidGame is gameStorage, ReentrancyGuard {
    address public gameRegistryAddress;

    constructor(address _gameRegistry) {
        gameRegistryAddress = _gameRegistry;
    }

    struct BidOrder {
        address ERC20Address;
        address userAddress;
        uint256 BidAmount;
    }
    // gameId => competitorIndex => BidOrder[]
    mapping(uint256 => mapping(uint8 => BidOrder[])) public Bids;

    event BidCreated(
        uint256 GameId,
        uint8 CompetitorIndex,
        address ERC20Address,
        uint256 Amount
    );

    // 0xe2899bddFD890e320e643044c6b95B9B0b84157A
    function Bid(
        uint256 _gameId,
        uint8 _competitorIndex,
        address _ERC20Address,
        uint256 _amount
    ) external nonReentrant {
        gameDetail memory detail = gameRegistry(gameRegistryAddress)
            .getGamedetail(_gameId);
        if (detail.addBidders) {
            require(
                gameRegistry(gameRegistryAddress).bidderVerification(
                    _gameId,
                    msg.sender
                ),
                "You are not Added as Bidder"
            );
        }

        require(block.timestamp > detail.bidStartTime, "Game not Started Yet");
        require(_ERC20Address != address(0), "0 Address Passed");
        require(_amount != 0, "You can't Bid with zero amount");
        BidOrder memory bid = BidOrder(_ERC20Address, msg.sender, _amount);
        Bids[_gameId][_competitorIndex].push(bid);

        totalBidAmount[_gameId][_competitorIndex] += _amount;

        // Send payment to the Pool
        require(
            IERC20(_ERC20Address).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Unable to tansfer Fund"
        );
        emit BidCreated(_gameId, _competitorIndex, _ERC20Address, _amount);
    }
}
