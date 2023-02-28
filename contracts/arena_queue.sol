// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "utils/HitchensOrderStatisticsTreeLib.sol";
import "utils/inter.sol";

contract Arena_Queue is Interconnected {

    using HitchensOrderStatisticsTreeLib for HitchensOrderStatisticsTreeLib.Tree;

    HitchensOrderStatisticsTreeLib.Tree tree;

    uint256 public MAX_TREE_SIZE;

    mapping(uint => uint) public idValueMap;

    uint[] public ids;

    uint deleteIndex = 0;

    constructor()  {
        MAX_TREE_SIZE = 1000;
    }


    function updateMaxTreeSize(uint maxTreeSize) external onlyOwner {
        require(maxTreeSize > 1, "Size must be greater than 1");
        MAX_TREE_SIZE = maxTreeSize;
    }

    function getQueueCount() public view returns (uint256) {
        return tree.count();
    }

    function getMaxQueueSize() public view returns (uint256) {
        return MAX_TREE_SIZE;
    }

    /**
     * @notice Insert item to tree
     * @param id - item unique identifier
     * @param value - item value (used for ordering)
     * @return removedId - id of deleted item or 0 if there was no deletion
     */
    function insertItem(uint id, uint value) external onlyBattleContract returns (uint removedId) {
        
        require(idValueMap[id] == 0, "duplicate id");

        // work around for unique values
        value = value * 1000000 + id;

        tree.insert(bytes32(id), value);
        idValueMap[id] = value;
        ids.push(id);

        if (tree.count() > MAX_TREE_SIZE) {
            do {
                removedId = ids[deleteIndex];
                deleteIndex++;
            }
            while (idValueMap[removedId] == 0);
            tree.remove(bytes32(removedId), idValueMap[removedId]);
            idValueMap[removedId] = 0;
            return removedId;
        } else
            return 0;
    }

    /**
     * @notice Remove item from tree
     * @param id - item unique identifier
     */

    function removeItem(uint id) external onlyBattleContract {
        require(idValueMap[id] != 0, "no found item");
        tree.remove(bytes32(id), idValueMap[id]);
        idValueMap[id] = 0;
    }

    
    /**
     * @notice Searching for nearest neighbor in  tree
     * @param id - item unique identifier
     * @return neighborId - nearest neighbor id
     */
    function getNearestNeighbor(uint id) public view returns (uint neighborId) {
        require(idValueMap[id] != 0, "no found item");
        require(tree.count() > 1, "few items in tree");

        uint value = idValueMap[id];
        // If there are other keys with the same value then just return any of them
        bytes32[] memory keys = tree.valueKeys(value);
        if (keys.length > 1) {
            if (keys[0] == bytes32(id)) {
                return uint(keys[1]);
            } else {
                return uint(keys[0]);
            }
        }
        // Getting the values above and below in tree
        else {
            uint next = tree.next(value);
            uint previous = tree.prev(value);

            // If value above does not exist, then return  value below
            if (next == 0) {
                return uint(tree.valueKeys(previous)[0]);
            }

            // If value below does not exist, then return  value above
            if (previous == 0) {
                return uint(tree.valueKeys(next)[0]);
            }

            if ((next - value) >= (value - previous)) {
                return uint(tree.valueKeys(previous)[0]);
            } else {
                return uint(tree.valueKeys(next)[0]);
            }
        }

    }


}
