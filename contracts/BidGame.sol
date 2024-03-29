// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./gameStorage.sol";
import "./gameRegistry.sol";
import "./dreamBidFee.sol";
import "./Libraries/LibGame.sol";
import "./Libraries/LibCalculations.sol";

contract BidGame is gameStorage, ReentrancyGuard {
    address public gameRegistryAddress;
    address public dreamBidFeeAddress;
    bool public _restrictionOnGame;

    // gameId => CompetitorIndex => totalBidAmount
    mapping(uint256 => mapping(uint8 => uint256)) public totalBidAmount;

    // gameId => competitorIndex => BidOrder[]
    mapping(uint256 => mapping(uint8 => BidOrder[])) public Bids;
    /*
        BidIndex will always be plus one to actual Bid Index
        because if user will again bid then his Bids[_gameId][_competitorIndex][bidIndex - 1].BidAmount will only change
    */
    // userAddress => gameId => BidIndex
    mapping(address => mapping(uint256 => uint256)) public userBidIndex;

    struct BidOrder {
        address currency;
        address userAddress;
        uint256 BidAmount;
        bool withdrawn;
    }

    constructor(address _gameRegistry, address _dreamBidFeeAddress) {
        gameRegistryAddress = _gameRegistry;
        dreamBidFeeAddress = _dreamBidFeeAddress;
    }

    event BidCreated(
        uint256 GameId,
        uint8 CompetitorIndex,
        address Currency,
        uint256 Amount,
        uint256 totalBid
    );

    event wihdrawSuccess(
        uint256 GameId,
        uint256 Amount
    );

    function restrictionOnGame(bool _restriction) external nonReentrant {
        require(
            msg.sender ==
                dreamBidFee(dreamBidFeeAddress).getProtocolOwnerAddress(),
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

        emit BidCreated(_gameId, _competitorIndex, detail.currency, _amount, totalBidAmount[_gameId][_competitorIndex]);
    }

    function losingCompetitorsAmount(uint256 _gameId, uint8 _competitorsLimit, uint256 _winnersLength, uint8[] memory _winners)
        public
        view
        returns (uint256)
    {
        uint256 amount;
        // gameRegistry(gameRegistryAddress).getWinners(_gameId);
        for (uint8 i = 0; i < _competitorsLimit; i++) {
            for (uint8 j = 0; j < _winnersLength; j++) {
                if (i != _winners[j]) {
                    amount += totalBidAmount[_gameId][i];
                }
            }
        }
        return amount;
    }

    function getTotalBidAmount(uint256 _gameId, uint8 _competitorIndex) public view returns(uint256){
        return totalBidAmount[_gameId][_competitorIndex];
    }

    function withdraw(
        uint256 _gameId,
        uint8 _competitorIndex,
        address _ERC20Address,
        address _receiver
    ) external nonReentrant {
        gameDetail memory detail = gameRegistry(gameRegistryAddress)
            .getGamedetail(_gameId);
        if(!detail.winnerDecided){
            require(block.timestamp > detail.bidEndTime, "Game not Finished Yet");
        }
        uint256 index = userBidIndex[msg.sender][_gameId];
        require(index > 0, "You have not Bid in this game");
        require(
            !Bids[_gameId][_competitorIndex][index - 1].withdrawn,
            "You have already withdrawn"
        );
        Bids[_gameId][_competitorIndex][index - 1].withdrawn = true;
        uint8 CompetitorsLimit = gameRegistry(gameRegistryAddress)
            .getCompetitorsLimit();
        uint256 WinnersLength = gameRegistry(gameRegistryAddress)
            .getWinnersLength(_gameId);
        uint8[] memory winners = gameRegistry(gameRegistryAddress)
            .getWinners(_gameId);
        uint256 _losingCompetitorsAmount = losingCompetitorsAmount(_gameId, CompetitorsLimit, WinnersLength, winners);
        uint256 bidIndex = userBidIndex[msg.sender][_gameId];
        uint256 userAmount = Bids[_gameId][_competitorIndex][bidIndex - 1].BidAmount;
        uint256 winningAmount = totalBidAmount[_gameId][_competitorIndex];
        uint256 payout = LibCalculations.calculateAmount(_losingCompetitorsAmount, winningAmount, userAmount);
        // transfering Amount to Winner
        require(
            IERC20(_ERC20Address).transfer(_receiver, payout),
            "unable to transfer to receiver"
        );
        emit wihdrawSuccess(_gameId, payout);
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
