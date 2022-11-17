// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 */
interface IEIP1998 is IERC165 {

    /**
     * @dev Returns how much difference royalty is owed and to whom, based on a cost price and sale price that 
	 * may be denominated in any unit of exchange. 
	 * The royalty amount is denominated and should be paid in that same unit of exchange.
	 * Note: using fixedRoyaltyInfo instead if costPrice doesn't exist.
     */
    function diffRoyaltyInfo(uint256 tokenId, uint256 costPrice, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

	/**
     * @dev Returns how much fixed royalty is owed and to whom, based on a sale price that 
	 * may be denominated in any unit of exchange. 
	 * The royalty amount is denominated and should be paid in that same unit of exchange.
	 * Note: The stub royalty is the recent royalty amount. if ignoreStub is false, then the result is :
	 * Min(fixedRoyalty, recentRoyaltyAmount). Otherwise, just return fixedRoyalty.
     */
    function fixedRoyaltyInfo(uint256 tokenId, uint256 salePrice, bool ignoreStub)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}