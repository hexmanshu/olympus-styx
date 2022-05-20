// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/// ============ Interfaces ============

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IOlympusPro {
    // 0, 0,  0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5 (ohm)
    function liveMarketsFor(
        bool _creator,
        bool _base,
        address _address
    ) external view returns (uint256[] memory);

    function deposit(
        uint48 _id,
        uint256[2] memory _amounts, // ohm, dai (amount in, amount out)
        address[2] memory _addresses // recipient, refferer (0x245cc372C84B3645Bf0Ffe6538620B04a217988B)
    )
        external
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        );
}

contract Styx {
    address internal immutable OWNER;
    IERC20 internal immutable OHM;
    IERC20 internal immutable DAI;
    IUniswapV2Router internal immutable SUSHI;
    IOlympusPro internal immutable BOND;

    constructor(
        address _OHM,
        address _BOND,
        address _DAI,
        address _SUSHI
    ) {
        OWNER = msg.sender;
        OHM = IERC20(_OHM);
        DAI = IERC20(_DAI);
        SUSHI = IUniswapV2Router(_SUSHI);
        BOND = IOlympusPro(_BOND);

        IERC20(_OHM).approve(
            _BOND,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        IERC20(_DAI).approve(
            _BOND,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        IERC20(_OHM).approve(
            _SUSHI,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        IERC20(_DAI).approve(
            _SUSHI,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    function execute(
        uint256 _amountOhm,
        uint256 _amountDai,
        uint48 _id
    ) external {
        require(msg.sender == OWNER);

        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(OHM);

        SUSHI.swapExactTokensForTokens(
            _amountDai,
            _amountOhm,
            path,
            address(this),
            block.timestamp + 60
        );

        uint256[2] memory _amounts;
        address[2] memory _addresses;

        _amounts[0] = _amountOhm;
        _amounts[1] = _amountDai;

        _addresses[0] = address(this);
        _addresses[1] = address(0x245cc372C84B3645Bf0Ffe6538620B04a217988B);

        BOND.deposit(_id, _amounts, _addresses);
    }

    function withdrawDai() external {
        require(msg.sender == OWNER);
        DAI.transfer(OWNER, DAI.balanceOf(address(this)));
    }

    function withdrawOhm() external {
        require(msg.sender == OWNER);
        OHM.transfer(OWNER, DAI.balanceOf(address(this)));
    }
}
