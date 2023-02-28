// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract ToString {

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * @dev debug line: require(sum1 > 0, string(abi.encodePacked('Zero Sum!', toString(r1[0] * fairWeights[0]))));
     */
    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory Booster = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            Booster[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(Booster);
    }
}