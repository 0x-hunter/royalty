// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IEIP1998.sol";

abstract contract EIP1998 is IEIP1998, ERC165 {

	struct RoyaltyInfo {
        address receiver;        // receiver for tax
        uint8 diffRoyaltyRate;   // Differential tax rate, range in [0-10000]
		uint8 fixedRoyaltyRate;  // fixed tax rate, range in [0-10000]
    }

	// Using this when royalty info is not exist in _tokenRoyaltyInfo for specific tokenId.
	RoyaltyInfo private _defaultRoyaltyInfo;

	// Mapping from token ID to royalty info
	mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

	// store the recent royalty value
	uint256 private _stubRoyalty;

	/**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IEIP1998).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IEIP1998
     */
    function diffRoyaltyInfo(
		uint256 _tokenId, 
		uint256 costPrice, 
		uint256 salePrice
	) external view returns (address, uint256) {
		if (salePrice - costPrice <= 0) {
			return (_defaultRoyaltyInfo.receiver, 0);
		}

		RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];
		if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

		uint256 royaltyAmount = ((salePrice - costPrice) * royalty.diffRoyaltyRate) / uint256(_feeDenominator());

		return (royalty.receiver, royaltyAmount);
	}

	/**
     * @inheritdoc IEIP1998
     */
    function fixedRoyaltyInfo(
		uint256 tokenId, 
		uint256 salePrice,
		bool ignoreStub
	) external view returns (address, uint256) {
		if (salePrice == 0) {
			return (_defaultRoyaltyInfo.receiver, 0);
		}

		RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];
		if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

		uint256 royaltyAmount = (salePrice * royalty.fixedRoyaltyRate) / uint256(_feeDenominator());
		if (ignoreStub) {
			return (royalty.receiver, royaltyAmount);
		}

		uint256 result = _minUint256(royaltyAmount, _stubRoyalty);
		return (royalty.receiver, result);
	}

	/**
	 * @dev setter & getter for stubRoyaltyAmount
	 */
	function _setStubRoyaltyAmount(uint256 stubRoyalty) internal {
		_stubRoyalty = stubRoyalty;
	}

	function _stubRoyaltyAmount() internal view returns (uint256) {
		return _stubRoyalty;
	}

	/**
	 * @dev set DefaultRoyaltyInfo.
	 */
	function _setDefaultRoyalty(
		address receiver, 
		uint8 diffNumber, 
		uint8 fixedNumber
	) internal virtual {
        require(diffNumber <= _feeDenominator() && diffNumber >= 0, "EIP1998: diffNumber rate must be rage in 0-10000");
		require(fixedNumber <= _feeDenominator() && fixedNumber >= 0, "EIP1998: fixedNumber rate must be rage in 0-10000");
        require(receiver != address(0), "EIP1998: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, diffNumber, fixedNumber);
    }

	/**
	 * @dev set RoyaltyInfo for specific tokenId.
	 */
	function _setTokenRoyalty(
		uint256 tokenId,
		address receiver, 
		uint8 diffNumber, 
		uint8 fixedNumber
	) internal virtual {
        require(diffNumber <= _feeDenominator() && diffNumber >= 0, "EIP1998: diffNumber rate must be rage in 0-10000");
		require(fixedNumber <= _feeDenominator() && fixedNumber >= 0, "EIP1998: fixedNumber rate must be rage in 0-10000");
        require(receiver != address(0), "EIP1998: invalid receiver");

		_tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, diffNumber, fixedNumber);
    }

	/**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

	/**
     * @dev get the min one between two uint256 number
     */
	function _minUint256(uint256 _x, uint256 _y) internal pure returns (uint256) {
		return _x >= _y ? _y : _x;
	}

	/**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }
}