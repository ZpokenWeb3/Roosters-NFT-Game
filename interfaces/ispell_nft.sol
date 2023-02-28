// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface ISpell_NFT {
    function hatchSpell(address account, uint256 eggQuality) external returns (uint256);
    function isStaked(uint256 _id) external returns (bool);
    function setStaked(uint256 _id, bool _status) external;
    function getStats(uint256 _id) external returns (uint256[3] memory);
    function ownerOf(uint256 _id) external returns (address);
    function burnSpellNft(uint256 _spell_id) external;
}