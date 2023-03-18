// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./gameStorage.sol";

contract gameRegistry is gameStorage, ReentrancyGuard {
    using Counters for Counters.Counter;

    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

    event gameListedForFixPrice(
        address ERC20contract,
        uint256 gameId,
        uint256 price,
        uint256 bidStartTime,
        uint256 bidEndTime
    );

    event BidderAdded(uint256 gameId, address BidderAddress);
    event BidderRemoved(uint256 gameId, address BidderAddress);

    modifier onlyGameOwner(uint256 _gameId) {
        gameDetail storage game = gamesDetail[_gameId];
        require(msg.sender == game.gameOwner, "You are not the game owner");
        _;
    }

    function listGame(
        address _ERC20contract,
        uint256 _price,
        uint256 _bidStartTime,
        uint256 _bidEndTime,
        bool _addBidders
    ) external nonReentrant {
        require(
            _ERC20contract != address(0),
            "you can't do this with zero address"
        );
        uint256 gameId_ = ++gameId;
        gameDetail memory gameData = gameDetail(
            _ERC20contract,
            msg.sender,
            block.timestamp,
            _price,
            true,
            _addBidders,
            block.timestamp + _bidStartTime,
            block.timestamp + _bidEndTime,
            gameState.STARTED
        );
        gamesDetail[gameId_] = gameData;

        emit gameListedForFixPrice(
            _ERC20contract,
            gameId_,
            _price,
            block.timestamp + _bidStartTime,
            block.timestamp + _bidEndTime
        );
    }

    function addBidders(uint256 _gameId, address _bidderAddress)
        external
        nonReentrant
    {
        require(_bidderAddress != address(0), "0 address given");
        gameDetail storage game = gamesDetail[_gameId];
        require(game.gameOwner == msg.sender, "You are not owner");
        require(block.timestamp < game.bidStartTime, "Game has been started");
        require(game.addBidders, "You can't add Bidder");
        _addBidder(_gameId, _bidderAddress);
        emit BidderAdded(_gameId, _bidderAddress);
    }

    function _addBidder(uint256 _gameId, address _bidderAddress) private {
        bidderAddressIndex[_gameId][_bidderAddress] = Bidders[_gameId].length;
        Bidders[_gameId].push(_bidderAddress);
    }

    function removeBidder(uint256 _gameId, address _bidderAddress)
        external
        nonReentrant
    {
        require(_bidderAddress != address(0), "0 address given");
        gameDetail storage game = gamesDetail[_gameId];
        require(game.gameOwner == msg.sender, "You are not owner");
        require(block.timestamp < game.bidStartTime, "Game has been started");
        require(game.addBidders, "You can't add Bidder");
        _removeBidder(_gameId, _bidderAddress);
        emit BidderRemoved(_gameId, _bidderAddress);
    }

    function _removeBidder(uint256 _gameId, address _bidderAddress) private {
        uint256 lastBidderIndex = Bidders[_gameId].length - 1;
        address lastBidderAddress = Bidders[_gameId][lastBidderIndex];
        if (_bidderAddress != lastBidderAddress) {
            uint256 bidderIndex = bidderAddressIndex[_gameId][_bidderAddress];
            Bidders[_gameId][bidderIndex] = lastBidderAddress;
            bidderAddressIndex[_gameId][lastBidderAddress] = bidderIndex;
        }
        delete bidderAddressIndex[_gameId][_bidderAddress];
        Bidders[_gameId].pop();
    }
}
