// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

contract StorageContract1 {
    struct Slot0 {
        address treasuryAddress;
        uint16 fee;
        uint16 distFee;
    }

    Slot0 public slot0; 

    constructor() {
        setAddress();
    }

    function setAddress() public  {
        slot0.treasuryAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        slot0.fee = 1;
        slot0.distFee = 1;
    }

    // this returns: 0x0000000000000000000100015b38da6a701c568545dcfcb03fcb875f56beddc4
    // breakdown:
    // 0x0000000000000000 0001 0001 5b38da6a701c568545dcfcb03fcb875f56beddc4
    //                    ↑    ↑    ↑
    //                distFee fee treasuryAddress
    //
    // 0x0000000000000000 -> padding
    // 0001 -> distFee
    // 0001 -> fee
    // 5b38da6a701c568545dcfcb03fcb875f56beddc4 -> treasuryAddress
    function getSlot0() public view returns(bytes32 ret) {
        assembly {
            ret := sload(0) // read slot0
        }
    }

    function getSlotAndOffset() public pure returns (uint256 slot, uint256 offset) {
        assembly {
            slot := slot0.slot
            offset := slot0.offset
        }
    }

    function getSlot0Values() public view returns (address treasuryAddress, uint16 fee, uint16 distFee) {
        assembly {
            let value := sload(slot0.slot) // slot 0
            // 0x0000000000000000000100015b38da6a701c568545dcfcb03fcb875f56beddc4
            // gonna fall off:  00015b38da6a701c568545dcfcb03fcb875f56beddc4
            // and replaced by: 00000000000000000000000000000000000000000000
            // 0x0000000000000000 0001 00000000000000000000000000000000000000000000
            
            // slot0.distFee.offset = 22 bytes * 8 = 176 bits
            let shifted := shr(mul(22, 8), value)
            // 0x0000000000000000000000000000000000000000000000000000000000000001

            // now we mask with 0xffff (2 bytes)
            // 0x0000000000000000000000000000000000000000000000000000000000000001
            // 0x000000000000000000000000000000000000000000000000000000000000ffff
            distFee := and(shifted, 0xffff)
        }
    }

    // we pass in '10' which equals to '0xa' in hex
    function setDistFee(uint16 newDistFee) external {
        assembly {
            // newDistFee = 0x000000000000000000000000000000000000000000000000000000000000000a

            let value := sload(slot0.slot) // slot 0
            // value = 0x0000000000000000000100015b38da6a701c568545dcfcb03fcb875f56beddc4

            let clearedSlot0 := and(value, 0x00000000000000000000000fffffffffffffffffffffffffffffffffffffffff)

            // value =          0x0000000000000000000100015b38da6a701c568545dcfcb03fcb875f56beddc4
            // mask =           0x00000000000000000000000fffffffffffffffffffffffffffffffffffffffff
            // clearedSlot0 =   0x0000000000000000000000015b38da6a701c568545dcfcb03fcb875f56beddc4

            let shiftedNewDistFee := shl(mul(22, 8), newDistFee)
            // shiftedNewDistFee = 0x0000000000000000000a00000000000000000000000000000000000000000000

            let newValue := or(shiftedNewDistFee, clearedSlot0)
            // shiftedNewDistFee = 0x0000000000000000000a00000000000000000000000000000000000000000000
            // clearedSlot0 =      0x0000000000000000000000015b38da6a701c568545dcfcb03fcb875f56beddc4
            // newValue =          0x0000000000000000000a00015b38da6a701c568545dcfcb03fcb875f56beddc4
            sstore(slot0.slot, newValue)
        }
    }

    function getValues() public view returns (address treasuryAddress, uint16 fee, uint16 distFee) {
        assembly {
            let slot := sload(slot0.slot) // slot 0

            // treasuryAddress: lowest 20 bytes
            treasuryAddress := and(slot, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

            // fee: shift right 160 bits (20 bytes), then mask 16 bits
            fee := and(shr(160, slot), 0xFFFF)

            // distFee: shift right 176 bits (22 bytes), then mask 16 bits
            distFee := and(shr(176, slot), 0xFFFF)
        }
    }
}