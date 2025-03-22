// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

contract StorageContract {
    struct Allocation {
        uint256 polAmount;
        uint256 sharePriceNum;
        uint256 sharePriceDenom;
    }

    struct SlotData {
        // slot 0
        address treasuryAddress; // 20 bytes
        uint16 fee; // 2 bytes
        uint16 distFee; // 2 bytes

        // slot 1
        mapping(address => mapping(address => Allocation)) allocations;

        // slot 2
        address[] validatorAddresses;

        // slot 3
        mapping(address => address[]) distributors;
    }

    SlotData public slotData; 

    constructor() {
        // slot 0 in struct
        slotData.treasuryAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        slotData.fee = 1;
        slotData.distFee = 1;

        // slot 1 in struct
        slotData.allocations[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4][0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = Allocation(11, 22, 33);

        // slot 2 in struct
        slotData.validatorAddresses.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        slotData.validatorAddresses.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    
        // slot 3 in struct
        slotData.distributors[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4].push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        slotData.distributors[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4].push(0x17F6AD8Ef982297579C203069C1DbfFE4348c372);
    }

    function getAllocations(address outerKey, address innerKey) public view returns (Allocation memory allocation) {
        // slotData is at slot 0 => so slotData.allocations lives at slot 1
        uint256 allocationsSlot = 1;
        
        uint256 outerSlot = uint256(
            keccak256(
                abi.encode(
                    outerKey, 
                    allocationsSlot
                )
            )
        );
        uint256 finalSlot = uint256(
            keccak256(
                abi.encode(
                    innerKey, 
                    outerSlot
                )
            )
        );

        uint256 polAmount;
        uint256 sharePriceNum;
        uint256 sharePriceDenom;

        assembly {
            polAmount := sload(finalSlot) // slot 0 of Allocation
            sharePriceNum := sload(add(finalSlot, 1)) // slot 1 of Allocation
            sharePriceDenom := sload(add(finalSlot, 2)) // slot 2 of Allocation
        }

        return Allocation(polAmount, sharePriceNum, sharePriceDenom);
    }

    function getAllocations() public view returns (Allocation memory allocation) {
        return getAllocations(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    }

    function getValidatorAddressesLength() public pure returns (uint256 length) {
        // slotData is at slot 0 => so slotData.validatorAddresses lives at slot 2
        uint256 validatorAddressesSlot = 2;

        assembly {
            length := validatorAddressesSlot
        }
    }

    function getValidatorAddress(uint256 index) public view returns (address validatorAddress) {
        // slotData is at slot 0 => so slotData.validatorAddresses lives at slot 2
        uint256 validatorAddressesSlot = 2;

        bytes32 location = keccak256(abi.encode(validatorAddressesSlot));

        assembly {
            validatorAddress := sload(add(location, index))
        }
    }

    function getDistributorsLength(address key) public view returns (uint256 length) {
        // slotData is at slot 0 => so slotData.distributors lives at slot 3
        uint256 distributorsSlot = 3;

        bytes32 location = keccak256(abi.encode(key, distributorsSlot));

        assembly {
            length := sload(location)
        }
    }

    function getDistributor(address key, uint256 index) public view returns (address distributor) {
        // slotData is at slot 0 => so slotData.distributors lives at slot 3
        uint256 distributorsSlot = 3;

        //  get start of array data
        bytes32 location = keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        address(key),
                        uint256(distributorsSlot)
                    )
                )
            )
        );

        // read the value at index
        assembly {
            distributor := sload(add(location, index))
        }
    }
}
