// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IItem_NFT {
    function hatchItem(address account, uint256 eggQuality) external returns (uint256);
    function isStaked(uint256 _id) external returns (bool);
    function setStaked(uint256 _id, bool _status) external;
    function getStats(uint256 _id) external returns (uint256[6] memory);
    function ownerOf(uint256 _id) external returns (address);
    function burnItemNft(uint256 _itemId) external;
    function craftWithSprig(uint256 updatedItemId, bool levelUp, uint256 mintSprigQuality, uint256 burnedItemId) external;
    function craftMixSameType(uint256 updatedItemId, uint256 sameTypeBonus, uint256 burnedItemId) external;
    function craftItemLiveSacrifice(uint256 updatedItemId, uint256 addedBonus) external;
    function craftNewItem(address account, uint256 _quality, uint256 _itemType) external returns (uint256);
}