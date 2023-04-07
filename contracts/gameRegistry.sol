// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./gameStorage.sol";
import "./dreamBidFee.sol";
import "./Libraries/LibGame.sol";

contract gameRegistry is gameStorage, ReentrancyGuard {
    using Counters for Counters.Counter;

    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    // 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

    address public dreamBidFeeAddress;

    constructor(address _dreamBidFeeAddress) {
        dreamBidFeeAddress = _dreamBidFeeAddress;
    }

    event gameListedForFixPrice(
        address Currency,
        uint256 gameId,
        uint256 minPrice,
        uint256 bidStartTime,
        uint256 bidEndTime
    );

    event BidderAdded(uint256 gameId, address BidderAddress);
    event BidderRemoved(uint256 gameId, address BidderAddress);
    event CompetitorsSet(
        uint256 indexed gameId,
        LibGame.Competitor[] Competitors
    );
    event DecidedWinners(uint256 gameId, uint8[] Winners);

    // error sameCompetitor(string, address);

    modifier onlyGameOwner(uint256 _gameId) {
        gameDetail storage game = gamesDetail[_gameId];
        require(msg.sender == game.gameOwner, "You are not the game owner");
        _;
    }

    function listGame(
        address _currency,
        uint256 _minPrice,
        uint256 _bidStartTime,
        uint256 _bidEndTime,
        bool _addBidders,
        uint8 _totleCompetitors,
        LibGame.Competitor[] memory competitors
    ) external nonReentrant {
        require(
            _totleCompetitors <= CompetitorsLimit,
            "Competitors > CompetitorsLimit"
        );
        require(_totleCompetitors == competitors.length, "Total Competitors");
        uint256 gameId_ = ++gameId;
        gameDetail memory gameData = gameDetail(
            _currency,
            msg.sender,
            block.timestamp,
            _minPrice,
            true,
            _addBidders,
            block.timestamp + _bidStartTime,
            block.timestamp + _bidEndTime,
            gameState.STARTED
        );
        gamesDetail[gameId_] = gameData;

        _setCompetitorsByGameId(gameId_, competitors);

        emit gameListedForFixPrice(
            _currency,
            gameId_,
            _minPrice,
            block.timestamp + _bidStartTime,
            block.timestamp + _bidEndTime
        );
    }

    function setCompetitorsLimit(uint8 _competitorsLimit) public nonReentrant {
        require(
            msg.sender ==
                dreamBidFee(dreamBidFeeAddress).getProtocolOwnerAddress(),
            "You are not the Protocol Owner"
        );
        CompetitorsLimit = _competitorsLimit;
    }

    function getGamedetail(uint256 _gameId)
        external
        view
        returns (gameDetail memory)
    {
        return gamesDetail[_gameId];
    }

    // [["Hi"],["Shrish"],["Sonal"]]
    function _setCompetitorsByGameId(
        uint256 _gameId,
        LibGame.Competitor[] memory competitors
    ) private {
        delete Competitors[_gameId];
        for (uint8 i = 0; i < competitors.length; i++) {
            for (uint8 j = 0; j < i; j++) {
                if (
                    keccak256(abi.encode(competitors[i])) ==
                    keccak256(abi.encode(competitors[j]))
                ) {
                    revert("Same competitor name Not Allowed");
                }
            }
            Competitors[_gameId].push(competitors[i]);
        }
        emit CompetitorsSet(_gameId, competitors);
    }

    function getCompetitors(uint256 _gameId)
        external
        view
        returns (LibGame.Competitor[] memory)
    {
        return Competitors[_gameId];
    }

    function getCompetitorsById(uint256 _gameId, uint8 _competitorIndex)
        external
        view
        returns (LibGame.Competitor memory)
    {
        return Competitors[_gameId][_competitorIndex];
    }

    function addBidders(uint256 _gameId, address _bidderAddress)
        external
        nonReentrant
    {
        require(_bidderAddress != address(0), "0 address given");
        gameDetail storage game = gamesDetail[_gameId];
        require(game.addBidders, "You can't add Bidder");
        require(game.gameOwner == msg.sender, "You are not owner");
        require(block.timestamp < game.bidStartTime, "Game has been started");
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

    function bidderVerification(uint256 _gameId, address _bidderAddress)
        external
        view
        returns (bool isVerified)
    {
        uint256 Index = bidderAddressIndex[_gameId][_bidderAddress];
        if (Bidders[_gameId][Index] == _bidderAddress) {
            isVerified = true;
        }
    }

    function decideWinner(uint256 _gameId, uint8[] memory winners) external {
        require(
            msg.sender ==
                dreamBidFee(dreamBidFeeAddress).getProtocolOwnerAddress(),
            "You are not the Protocol Owner"
        );
        for (uint8 i = 0; i < winners.length; i++) {
            Winners[_gameId].push(winners[i]);
        }
        emit DecidedWinners(_gameId, winners);
    }

    function getWinners(uint256 _gameId)
        external
        view
        returns (uint8[] memory)
    {
        return Winners[_gameId];
    }
}
