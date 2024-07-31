// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// MyOApp imports
import { MyOApp } from "../../contracts/MyOAppA.sol";
import { MyOAppB } from "../../contracts/MyOAppB.sol";

// OApp imports
import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Forge imports
import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

contract MyOAppTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 private aEid = 1;
    uint32 private bEid = 2;

    MyOApp private aOApp;
    MyOAppB private bOApp;

    address private userA = address(0x1);
    address private userB = address(0x2);
    uint256 private initialBalance = 100 ether;

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);

        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        aOApp = MyOApp(_deployOApp(type(MyOApp).creationCode, abi.encode(address(endpoints[aEid]), address(this))));

        bOApp = MyOAppB(_deployOApp(type(MyOAppB).creationCode, abi.encode(address(endpoints[bEid]), address(this))));

        address[] memory oapps = new address[](2);
        oapps[0] = address(aOApp);
        oapps[1] = address(bOApp);
        this.wireOApps(oapps);
    }

    // function test_ab() public {
    //     bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0); // gas settings for A -> B

    //     // Use the return call quote to generate a new quote for A -> B.
    //     // src chain cost + price of gas that I want to send + fees for my chosen security Stack / Executor
    //     MessagingFee memory sendFee = aOApp.quote(bEid, "Chain A says hello!", sendOptions, false);

    //     // Use the new quote for the msg.value of the send call.
    //     vm.startPrank(userA);
    //     aOApp.send{value: sendFee.nativeFee}(
    //         bEid,
    //         "Chain A says hello!",
    //         sendOptions
    //     );

    //     verifyPackets(bEid, addressToBytes32(address(bOApp)));
    //     verifyPackets(aEid, addressToBytes32(address(aOApp)));

    //     assertEq(bOApp.data(), "Chain A says hello!");
    //     assertEq(aOApp.data(), "Nothing received yet.");
    // }

    function test_aba() public {
        
        bytes memory sendOptionsB = OptionsBuilder.newOptions().addExecutorLzReceiveOption(500000, 0); // gas settings for A -> B
        MessagingFee memory sendFeeB = bOApp.quote(aEid, "Chain A says hello!", sendOptionsB, false);

        // Use the return call quote to generate a new quote for A -> B.
        // src chain cost + price of gas that I want to send + fees for my chosen security Stack / Executor
        bytes memory sendOptionsA = OptionsBuilder.newOptions().addExecutorLzReceiveOption(500000, uint128(sendFeeB.nativeFee)); // gas settings for A -> B
        MessagingFee memory sendFeeA = aOApp.quote(bEid, "Chain A says hello!", sendOptionsA, false);

        // Use the new quote for the msg.value of the send call.
        vm.startPrank(userA);
        aOApp.send{value: sendFeeA.nativeFee}(
            bEid,
            "Chain A says hello!",
            sendOptionsA
        );

        verifyPackets(bEid, addressToBytes32(address(bOApp)));
        verifyPackets(aEid, addressToBytes32(address(aOApp)));

        assertEq(bOApp.data(), "Chain A says hello!");
        assertEq(aOApp.data(), "Chain A says hello!");
    }
}