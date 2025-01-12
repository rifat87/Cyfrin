// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/**
 * @title DSCEngine
 * @author Tahzib Mahmud Rifat
 * 
 * The sytem is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 * 
 * It is similar to DAI if DAI had no gevernance, no fees, and was only backed by WETH and WBTC.
 * 
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral <= the $ backed value of all the DSC.
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based ont he MakerDAO DSS (DAI) system. 
 */

contract DSCEngine is ReentrancyGuard {

    /////////////////////////////// 
    ///   Errors            /////// 
    ///////////////////////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();




    /////////////////////////////// 
    ///   State Variables   /////// 
    ///////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; // this means 10% bonous



    mapping (address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping ( address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;



    /////////////////////////////// 
    ///   Event             /////// 
    ///////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount); 
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount);

    /////////////////////////////// 
    ///   Modifiers         /////// 
    /////////////////////////////// 
    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if(s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    } // we can use alt+<- (left arrow) to go back to the cursor to its previous position

    /////////////////////////////// 
    ///   Functions         /////// 
    ///////////////////////////////
    constructor( address[] memory tokenAddresses, address[] memory priceFeedAddresses,address dscAddress){
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        // For example ETH/USD, BTC/USD MKR/USD, etc
        for (uint i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /////////////////////////////// 
    ///   External Functions/////// 
    ///////////////////////////////

    /**
     * 
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposite
     * @param amountDscToMint The amount of decetralized stablecoin to mint
     * @notice this function will depisite your collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToMint) external{
        depositeCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @notice follows CEI(checks , effects , interactions)
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral( address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant{
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /**
     * 
     * @param tokenCollateralAddress 
     * @param amountCollateral  the amount to collateral to redeem
     * @param amountDscToBurn The amount of DSC to burn
     * This function burns DSC and redeems underlying collateral in one transaction
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) external {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemcollateral already check health factor    
    }
    
    //  in order to redeem  collateral:
    // 1. Health factor must be over 1 After collateral pulled
    // DRY: Don't repeat yourself
    // CEI: Check, Effects, Interactions
    function redeemCollateral( address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) nonReentrant{
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // $200 ETH -> $20 DSC
    /**
     * @notice follows CEI
     * @param amountDscToMint The amount of decentralization stablecoin to mint
     * @notice they must have moer collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much ($150 DSC, $100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }
    // Threshold to let's say 150%
    // $100 ETH Collateral -> $0
    // $0 DSC
    // Undercollateralized!!!

    // I'll pay back the $50 DSC -> Get all your collateral!
    // $74 ETH
    // -$50 DSC
    // $20

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // I don't think this would ever hit......
    }

    // If we do start nearing undercollateralization, we need someone to liquidate positions

    // $100 ETH backing $50 DSC
    // $20 ETH back $50 DSC <- DSC isn't worth $1 !!

    // $75 backing $50 DSC
    // Liquidator take $75 backing and burns off the $50 DSC

    //if someone is almost undercollateralized, we will pay you to liquidate them!

    /**
     * 
     * @param collateral The erc20 collateral address to liquidate from the user
     * @param user The user who has broken th ehealth factor. Their _healthFactor should be below MIN_HEALTH_FACTOR
     * @param debtToCover The amount of DSC you want to burn to improve the users health factor
     * @notice You can partially liquidate a user.
     * @notice You will get a liquidation bonous for taking The users funds
     * @notice This function working assumes the protocol wil be roughly 200$ overcollateralized i order for this to work
     * @notice A known bug would be if the protocol were 100$ or less collateralized, then we wouldn't be able to incentive the liquidators.abi
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     * 
     * Follows CEI: Checks, Effects, Interactions
     */
    function liquiddate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) nonReentrant {
        // need to check health factor of the user
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }

        // We want to burn their DSC "debt"
        // And take their collateral 
        // Bad User: $140 ETH, $100 DSC
        // debtToCover = $100
        // $100 of DSC == ?? ETH?
        // 0.05 ETH
        uint256 tokenAmountFormDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // And give them a 10$ bonus
        // so we are giving the liquidator of WETH for 100 DSC
        // We should implement a feature to liquidate in the event the protocol is insolvent 
        // And sweep extra amounts in to a treasury

        // 
        uint256 bonusCollateral = (tokenAmountFormDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFormDebtCovered + bonusCollateral;

        _redeemCollateral(user, msg.sender, collateral, totalCollateralToRedeem);
        // We need ot burn the DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor <= startingUserHealthFactor){
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor() external view {   }

    ////////////////////////////////////// 
    ///  Private Internal view Functions/////// 
    //////////////////////////////////////

    /**
     * 
     * @dev Low-level internal function, do not call unless the function calling it is checking for health factors being broken 
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_DSCMinted(onBehalfOf) -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this),
         amountDscToBurn);
        // This conditional is hypothtically unreachable
        if(!success){
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }


    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral) private {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralDeposited(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }
    function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /****
     * Returns how close to liquidation a user is
     * If a user goes below 1, then they can get liquidated
     */

    function _healthFactor(address user) private view returns (uint256){
        // total DSC minted
        // total collateral VALUE\
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // 1000 ETH * 50 = 50,000 / 100 = 500
        // $150 ETH / 100 DSC = 1.5
        // 150 * 50 = 7500 / 100 = (75 / 100) < 1

        // $150 ETH / 100 DSC = 1.5
        // return (collateralValueInUsd / totalDscMinted); // (150 / 100)
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

        // 1. Check health factor (do they have enough colateral?)
        // 2. Revert if they don't
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if ( userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }



    ////////////////////////////////////// 
    ///  Public External view Functions/////// 
    //////////////////////////////////////

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256) {
        // price of ETH (token)
        // $/ETH ETH ??
        // $2000 / ETH. $1000 = 0.5 ETH
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount they have deposited, and map it to the price, to get the USD value
        for(uint256 i = 0; i<s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);

        // (, int256 price,,,) = priceFeed.staleCheck;
        (, int256 price,,,) = priceFeed.latestRoundData();


        // 1 ETH = $1000
        // The returned value  from CL will be 1000 * 1e8

        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount)/ PRECISION; // (1000 * 1e *(1e10) * 1000 * 1e18)
    }

    function getAccountInformation( address user) external view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(msg.sender);
    }

    function _calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd) internal pure returns (uint256) {
        if(totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return(collateralAdjustedForThreshold = * 1e18) / totalDscMinted;
    }
}