// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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




    /////////////////////////////// 
    ///   State Variables   /////// 
    ///////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;



    mapping (address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping ( address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;



    /////////////////////////////// 
    ///   Event             /////// 
    ///////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount); 

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
    function depositCollateralAndMintDsc() external{
        
    }

    /**
     * @notice follows CEI(checks , effects , interactions)
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral( address tokenCollateralAddress, uint256 amountCollateral) external moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant{
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sendre, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {
        
    }
    
    function redeemCollateral() external {
        
    }

    // $200 ETH -> $20 DSC
    /**
     * @notice follows CEI
     * @param amountDscToMint The amount of decentralization stablecoin to mint
     * @notice they must have moer collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
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

    function burnDsc() external {
        
    }

    function liquiddate() external {
        
    }

    function getHealthFactor() external view {   }

    ////////////////////////////////////// 
    ///  Private Internal view Functions/////// 
    //////////////////////////////////////

    function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 collateralValueuInUsd) {
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

        // 1 ETH = $1000
        // The returned value  from CL will be 1000 * 1e8

        return (uint256(price) * ADDITIONAL_FEED_PRECISION) * amount/ PRECISION; // (1000 * 1e *(1e10) * 1000 * 1e18)
    }

}