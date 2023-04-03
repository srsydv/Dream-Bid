// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./gameStorage.sol";
import "./gameRegistry.sol";
import "./dreamBidFee.sol";
import "./Libraries/LibGame.sol";
// import "./Libraries/LibBidOnGame.sol";

contract BidGame is gameStorage, ReentrancyGuard {
    address public gameRegistryAddress;
    address public dreamBidFeeAddress;
    bool public _restrictionOnGame;

    constructor(address _gameRegistry, address _dreamBidFeeAddress) {
        gameRegistryAddress = _gameRegistry;
        dreamBidFeeAddress = _dreamBidFeeAddress;
    }

    event BidCreated(
        uint256 GameId,
        uint8 CompetitorIndex,
        address Currency,
        uint256 Amount
    );

    function restrictionOnGame(bool _restriction) external nonReentrant {
        require(
            msg.sender ==
                dreamBidFee(dreamBidFeeAddress).getAconomyOwnerAddress(),
            "You are not the Protocol Owner"
        );
        _restrictionOnGame = _restriction;
    }

    function Bid(
        uint256 _gameId,
        uint8 _competitorIndex,
        uint256 _amount
    ) external payable nonReentrant {
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
        if (detail.currency == address(0)) {
            _amount = msg.value;
        }

        require(block.timestamp > detail.bidStartTime, "Game not Started Yet");
        uint256 bidIndex = userBidIndex[msg.sender][_gameId];
        if (Bids[_gameId][_competitorIndex].length > 0 && bidIndex > 0) {
            Bids[_gameId][_competitorIndex][bidIndex - 1].BidAmount += _amount;
        } else {
            BidOrder memory bid = BidOrder(
                detail.currency,
                msg.sender,
                _amount,
                false
            );
            Bids[_gameId][_competitorIndex].push(bid);
        }

        userBidIndex[msg.sender][_gameId] = Bids[_gameId][_competitorIndex]
            .length;
        totalBidAmount[_gameId][_competitorIndex] += _amount;

        if (detail.currency != address(0)) {
            require(_amount != 0, "You can't Bid with zero amount");
            require(
                IERC20(detail.currency).transferFrom(
                    msg.sender,
                    address(this),
                    _amount
                ),
                "Unable to tansfer Fund"
            );
        }

        emit BidCreated(_gameId, _competitorIndex, detail.currency, _amount);
    }

    function losingCompetitorsAmount(uint256 _gameId)
        public
        view
        returns (uint256)
    {
        uint256 amount;
        // gameRegistry(gameRegistryAddress).getWinners(_gameId);
        for (uint8 i = 0; i < CompetitorsLimit; i++) {
            for (uint8 j = 0; j < Winners[_gameId].length; j++) {
                if (i != Winners[_gameId][j]) {
                    amount += totalBidAmount[_gameId][i];
                }
            }
        }
        return amount;
    }

    function withdraw(
        uint256 _gameId,
        uint8 _competitorIndex,
        bool toWollet
    ) external nonReentrant {
        gameDetail memory detail = gameRegistry(gameRegistryAddress)
            .getGamedetail(_gameId);
        require(block.timestamp > detail.bidEndTime, "Game not Finished Yet");
        uint256 index = userBidIndex[msg.sender][_gameId];
        require(index > 0, "You have not Bid in this game");
        require(
            !Bids[_gameId][_competitorIndex][index - 1].withdrawn,
            "You have already withdrawn"
        );
        uint256 _losingCompetitorsAmount = losingCompetitorsAmount(_gameId);
        // uint256 payout = LibCalculations.
        if (toWollet) {
            // userWollet[msg.sender][detail.currency] += _amount;
        }
    }

    function getGameBidAmount(uint256 _gameId, uint8 _competitorIndex)
        external
        view
        returns (uint256)
    {
        return totalBidAmount[_gameId][_competitorIndex];
    }

    function getContractbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _getContractbalance() public view returns (uint256) {
        return userBidIndex[msg.sender][1];
    }
}
