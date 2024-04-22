//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DPOSIndex {
    address public owner;
    address public uniswapRouter; // Address of the Uniswap Router
    address public treasury; // Address of the treasury

    uint public totalSupply;
    uint public posisSupply;

    uint public constant teamFee = 250000000000000; // 0.00025 ETH in wei
    
    event TokensPurchased(address indexed buyer, uint ethAmount, uint posisAmount);

    // Define the allocation percentages for each token in the index fund
    uint constant ETHAllocation = 25;
    uint constant ADAAllocation = 20;
    uint constant DOTAllocation = 15;
    uint constant SOLAllocation = 15;
    uint constant CROAllocation = 10;
    uint constant XTZAllocation = 10;
    uint constant AVAXAllocation = 5;
    
    constructor(address _uniswapRouter, address _treasury) {
        owner = msg.sender;
        uniswapRouter = _uniswapRouter;
        treasury = _treasury;
    }

    // Function to purchase POSI tokens by depositing ETH
    function purchasePOSI() external payable {
        require(msg.value > 0, "Must send ETH to purchase POSI");

        // Calculate team fee
        uint fee = (msg.value * teamFee) / 1 ether;
        uint amountToSwap = msg.value - fee;

        // Initialize array for asset paths on Uniswap
        address[] memory assetPaths = new address[](7);
        uint[] memory amountsOut = new uint[](7);

        // Define allocation percentages
        uint totalAllocation = ETHAllocation + ADAAllocation + DOTAllocation + SOLAllocation + CROAllocation + XTZAllocation + AVAXAllocation;

        // Calculate amounts of each asset based on allocation percentages
        amountsOut[0] = (amountToSwap * ETHAllocation) / totalAllocation;
        amountsOut[1] = (amountToSwap * ADAAllocation) / totalAllocation;
        amountsOut[2] = (amountToSwap * DOTAllocation) / totalAllocation;
        amountsOut[3] = (amountToSwap * SOLAllocation) / totalAllocation;
        amountsOut[4] = (amountToSwap * CROAllocation) / totalAllocation;
        amountsOut[5] = (amountToSwap * XTZAllocation) / totalAllocation;
        amountsOut[6] = (amountToSwap * AVAXAllocation) / totalAllocation;

        // Define asset paths
        assetPaths[0] = IUniswap(uniswapRouter).WETH(); // From WETH to ETH
        assetPaths[1] = address(ADA); // From WETH to ADA
        assetPaths[2] = address(DOT); // From WETH to DOT
        assetPaths[3] = address(SOL); // From WETH to SOL
        assetPaths[4] = address(CRO); // From WETH to CRO
        assetPaths[5] = address(XTZ); // From WETH to XTZ
        assetPaths[6] = address(AVAX); // From WETH to AVAX

        // Swap ETH for each asset on Uniswap
        for (uint i = 0; i < assetPaths.length; i++) {
            // Swap ETH for asset on Uniswap
            IUniswap(uniswapRouter).swapExactETHForTokens{value: amountsOut[i]}(
                0,
                getPathForETHToToken(assetPaths[i]),
                address(this),
                block.timestamp + 300
            );
        }

        // Transfer team fee to treasury
        payable(treasury).transfer(fee);

        // Mint POSI tokens to the sender
        uint posisAmount = calculatePOSI(amountToSwap - fee);
        posisSupply += posisAmount;

        // Emit event
        emit TokensPurchased(msg.sender, amountToSwap, posisAmount);
    }

    // Function to calculate POSI tokens based on deposited ETH
    function calculatePOSI(uint ethAmount) internal view returns (uint) {
        // Custom logic to calculate POSI tokens based on deposited ETH
        // For example:
        // return (ethAmount * 1000) / 1 ether;
        return ethAmount; // Temporary placeholder
    }

    // Helper function to get path for swapping ETH to token
    function getPathForETHToToken(address token) internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswap(uniswapRouter).WETH();
        path[1] = token;
        return path;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
