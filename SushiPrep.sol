
// File: contracts/interfaces/IUniswapV2ERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IUniswapV2ERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/interfaces/IUniswapV2Pair.sol


pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

// File: contracts/interfaces/IUniswapV2Router2.sol


pragma solidity ^0.6.12;

interface IUniswapV2Router2 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

// File: contracts/interfaces/IUniswapV2Factory.sol


pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// File: contracts/PickleMigrator.sol


pragma solidity ^0.6.12;





// Migrate from UNISWAP to SUSHISWAP
contract SushiPrep {
    IUniswapV2Factory sushiswapFactory = IUniswapV2Factory(
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
    );

    IUniswapV2Router2 sushiswapRouter = IUniswapV2Router2(
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    );

    IUniswapV2Factory uniswapFactory = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );

    IUniswapV2Router2 uniswapRouter = IUniswapV2Router2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    function migrateToSushiswapWithPermit(
        address token0,
        address token1,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        address pair = uniswapFactory.getPair(token0, token1);

        // Permit
        IUniswapV2ERC20(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );

        migrateToSushiswap(token0, token1, value);
    }

    function migrateToSushiswap(
        address token0,
        address token1,
        uint256 value
    ) public {
        // Removes liquidity from uniswap
        address uniPair = uniswapFactory.getPair(token0, token1);
        IUniswapV2ERC20(uniPair).transferFrom(msg.sender, address(this), value);
        IUniswapV2ERC20(uniPair).approve(address(uniswapRouter), value);
        uniswapRouter.removeLiquidity(
            token0,
            token1,
            value,
            0,
            0,
            address(this),
            now + 60
        );

        // Add liquidity to Sushiswap
        uint256 bal0 = IUniswapV2ERC20(token0).balanceOf(address(this));
        uint256 bal1 = IUniswapV2ERC20(token1).balanceOf(address(this));
        IUniswapV2ERC20(token0).approve(address(sushiswapRouter), bal0);
        IUniswapV2ERC20(token1).approve(address(sushiswapRouter), bal1);
        sushiswapRouter.addLiquidity(
            token0,
            token1,
            bal0,
            bal1,
            0,
            0,
            msg.sender,
            now + 60
        );

        // Refund sender any remaining tokens
        IUniswapV2ERC20(token0).transfer(
            msg.sender,
            IUniswapV2ERC20(token0).balanceOf(address(this))
        );
        IUniswapV2ERC20(token1).transfer(
            msg.sender,
            IUniswapV2ERC20(token1).balanceOf(address(this))
        );
    }
}
