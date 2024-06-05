// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {MessageHashUtils} from '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';
import {OpUSDCBridgeAdapter} from 'contracts/universal/OpUSDCBridgeAdapter.sol';
import {Test} from 'forge-std/Test.sol';
import {IOpUSDCBridgeAdapter} from 'interfaces/IOpUSDCBridgeAdapter.sol';

contract ForTestOpUSDCBridgeAdapter is OpUSDCBridgeAdapter {
  constructor(address _usdc, address _linkedAdapter) OpUSDCBridgeAdapter(_usdc, _linkedAdapter) {}

  function receiveMessage(address _user, uint256 _amount) external override {}

  function forTest_checkSignature(address _signer, bytes32 _messageHash, bytes memory _signature) public view {
    _checkSignature(_signer, _messageHash, _signature);
  }

  function _authorizeUpgrade(address newImplementation) internal override {}
}

abstract contract Base is Test {
  ForTestOpUSDCBridgeAdapter public adapter;

  address internal _usdc = makeAddr('opUSDC');
  address internal _linkedAdapter = makeAddr('linkedAdapter');
  address internal _signerAd;
  uint256 internal _signerPk;
  address internal _notSignerAd;
  uint256 internal _notSignerPk;

  function setUp() public virtual {
    (_signerAd, _signerPk) = makeAddrAndKey('signer');
    adapter = new ForTestOpUSDCBridgeAdapter(_usdc, _linkedAdapter);
  }
}

contract OpUSDCBridgeAdapter_Unit_Constructor is Base {
  /**
   * @notice Check that the constructor works as expected
   */
  function test_constructorParams() public {
    assertEq(adapter.USDC(), _usdc, 'USDC should be set to the provided address');
    assertEq(adapter.LINKED_ADAPTER(), _linkedAdapter, 'Linked adapter should be set to the provided address');
  }
}

contract ForTestOpUSDCBridgeAdapter_Unit_ReceiveMessage is Base {
  /**
   * @notice Execute vitual function to get 100% coverage
   */
  function test_doNothing() public {
    // Execute
    adapter.receiveMessage(address(0), 0);
  }
}

contract OpUSDCBridgeAdapter_Unit_CheckSignature is Base {
  /**
   * @notice Check that the signature is valid
   */
  function test_validSignature(bytes memory _message) public {
    vm.startPrank(_signerAd);
    bytes32 _hashedMessage = keccak256(abi.encodePacked(_message));
    bytes32 _digest = MessageHashUtils.toEthSignedMessageHash(_hashedMessage);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPk, _digest);
    bytes memory _signature = abi.encodePacked(r, s, v);
    vm.stopPrank();
    // Execute
    adapter.forTest_checkSignature(_signerAd, _hashedMessage, _signature);
  }

  /**
   * @notice Check that the signature is invalid
   */
  function test_invalidSignature(bytes memory _message, string memory _notSigner) public {
    (_notSignerAd, _notSignerPk) = makeAddrAndKey(_notSigner);
    vm.assume(_signerPk != _notSignerPk);
    bytes32 _hashedMessage = keccak256(abi.encodePacked(_message));
    bytes32 _digest = MessageHashUtils.toEthSignedMessageHash(_hashedMessage);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_notSignerPk, _digest);
    bytes memory _signature = abi.encodePacked(r, s, v);

    // Execute
    vm.expectRevert(abi.encodeWithSelector(IOpUSDCBridgeAdapter.IOpUSDCBridgeAdapter_InvalidSignature.selector));
    adapter.forTest_checkSignature(_signerAd, _hashedMessage, _signature);
  }
}
