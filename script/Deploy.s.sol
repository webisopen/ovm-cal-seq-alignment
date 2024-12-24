// SPDX-License-Identifier: MIT
// solhint-disable no-console,ordering,custom-errors
pragma solidity 0.8.24;

import {SeqAlign} from "../src/SeqAlign.sol";
import {DeployConfig} from "./DeployConfig.s.sol";
import {Deployer} from "./Deployer.sol";
import {TransparentUpgradeableProxy} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {console} from "forge-std/console.sol";

contract Deploy is Deployer {
    DeployConfig internal _cfg;

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    /// @notice The name of the script, used to ensure the right deploy artifacts
    ///         are used.
    function name() public pure override returns (string memory name_) {
        name_ = "Deploy";
    }

    function setUp() public override {
        super.setUp();
        string memory path =
            string.concat(vm.projectRoot(), "/deploy-config/", deploymentContext, ".json");
        _cfg = new DeployConfig(path);

        console.log("Deploying from %s", deployScript);
        console.log("Deployment context: %s", deploymentContext);
    }

    /* solhint-disable comprehensive-interface */
    function run() external {
        deployImplementations();

        deployProxies();
    }

    /// @notice Deploy all of the proxies
    function deployProxies() public {
        deployProxy("SeqAlign");
    }

    function deployProxy(string memory name_) public broadcast returns (address addr_) {
        address logic = mustGetAddress(_stripSemver(name_));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy({
            _logic: logic,
            initialOwner: _cfg.proxyAdminOwner(),
            _data: ""
        });

        string memory proxyName = string.concat(name_, "Proxy");
        save(proxyName, address(proxy));
        console.log("%s deployed at %s", proxyName, address(proxy));

        addr_ = address(proxy);
    }

    /// @notice Deploy all of the logic contracts
    function deployImplementations() public broadcast {
        deploySeqAlign();
    }

    function deploySeqAlign() public returns (address addr) {
        console.log("Deploying SeqAlign.sol");
        SeqAlign seqAlign = new SeqAlign(_cfg.ovmTaskAddress(), _cfg.templateAdmin());

        save("SeqAlign", address(seqAlign));
        console.log("SeqAlign deployed at %s", address(seqAlign));
        addr = address(seqAlign);
    }
}
