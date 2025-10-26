// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IMyToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

contract Bridge is Ownable {
    IMyToken public token;
    address public relayer;
    mapping(bytes32 => bool) public processed;
    event Deposit(
        bytes32 indexed depositId,
        address indexed from,
        uint256 amount,
        uint256 indexed toChainId,
        address to
    );
    event Redeem(
        bytes32 indexed depositId,
        address indexed to,
        uint256 amount,
        uint256 indexed fromChainId
    );
    event RelayerUpdated(
        address indexed oldRelayer,
        address indexed newRelayer
    );
    event TokenUpdated(address indexed oldToken, address indexed newToken);

    constructor(
        address tokenAddress,
        address initialRelayer,
        address initialOwner
    ) Ownable(initialOwner) {
        require(tokenAddress != address(0), "Zero token");
        token = IMyToken(tokenAddress);
        relayer = initialRelayer;
    }

    function deposit(
        bytes32 depositId,
        uint256 amount,
        uint256 toChainId,
        address to
    ) external {
        require(amount > 0, "Zero amount");
        require(!processed[depositId], "Deposit already processed");
        processed[depositId] = true;
        token.burnFrom(msg.sender, amount);
        emit Deposit(depositId, msg.sender, amount, toChainId, to);
    }

    function redeem(
        bytes32 depositId,
        address to,
        uint256 amount,
        uint256 fromChainId
    ) external {
        require(
            msg.sender == relayer || msg.sender == owner(),
            "Only relayer or owner"
        );
        require(amount > 0, "Zero amount");
        require(!processed[depositId], "Redeem already processed");
        processed[depositId] = true;
        token.mint(to, amount);

        emit Redeem(depositId, to, amount, fromChainId);
    }

    function setRelayer(address newRelayer) external onlyOwner {
        emit RelayerUpdated(relayer, newRelayer);
        relayer = newRelayer;
    }

    function setToken(address newToken) external onlyOwner {
        emit TokenUpdated(address(token), newToken);
        token = IMyToken(newToken);
    }
}
