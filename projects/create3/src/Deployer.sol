// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Create3.sol";

contract Deployer {
    string public constant COUNTER = "counter";

    event ContractDeployed(address indexed contractAddress, string contractName, bytes32 salt);

    struct Addresses {
        address counterAddress;
    }

    function getFutureAddresses() public view returns (Addresses memory) {
        Addresses memory addresses = Addresses(Create3.addressOf(keccak256(abi.encodePacked(COUNTER))));

        return addresses;
    }

    function deploy(string memory _saltString, bytes memory _creationCode) public returns (address deployedAddress) {
        bytes32 _salt = keccak256(abi.encodePacked(_saltString));
        deployedAddress = Create3.create3(_salt, _creationCode);
        emit ContractDeployed(deployedAddress, _saltString, _salt);
    }

    function deployWithCreationCodeAndConstructorArgs(
        string memory _saltString,
        bytes memory creationCode,
        bytes memory constructionArgs
    ) external returns (address) {
        bytes memory _data = abi.encodePacked(creationCode, constructionArgs);
        return deploy(_saltString, _data);
    }

    function deployWithCreationCode(string memory _saltString, bytes memory creationCode) external returns (address) {
        return deploy(_saltString, creationCode);
    }

    function addressOf(string memory _saltString) external view returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_saltString));
        return Create3.addressOf(_salt);
    }

    function addressOfSalt(bytes32 _salt) external view returns (address) {
        return Create3.addressOf(_salt);
    }

    /**
     * @notice Create the creation code for a contract with the given runtime code.
     *     @dev credit: https://github.com/0xsequence/create3/blob/master/contracts/test_utils/Create3Imp.sol
     */
    function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
        */

        return abi.encodePacked(hex"63", uint32(_code.length), hex"80600E6000396000F3", _code);
    }
}
