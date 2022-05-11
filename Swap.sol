// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function cbrt(uint n) internal pure returns (uint) {
        if (n == 0) {
            return 0;
        }

       uint[12] memory divisor = [
           uint(1000000),   uint(100000),   uint(10000),    uint(1000),
           uint(100),       uint(10),       uint(9),        uint(7),
           uint(5),         uint(3),        uint(2),        uint(1)
       ];

       uint[12] memory cube_root = [
           uint(100.000000 * 1e6), uint(46.415888  * 1e6), uint(21.544347  * 1e6),
           uint(10.000000  * 1e6), uint(4.641589   * 1e6), uint(2.154434   * 1e6),
           uint(2.080083   * 1e6), uint(1.912931   * 1e6), uint(1.709975   * 1e6),
           uint(1.442249   * 1e6), uint(1.259921   * 1e6), uint(1.000000   * 1e6)
       ];

       uint a = n;
       uint r = 1;
       for ( uint j = 0; j < divisor.length; ) {
           if ( a >= divisor[j] ) {
               r = (r * cube_root[j]) / 1e6;
               a /= divisor[j];
           } else if ( a <= 1) {
               break;
           } else {
               j++;
           }
       }
       return r;
   }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}


contract KPISwap {
    using SafeMath for uint256;

    uint256 constant TOKEN_COUNT = 1000000;

    mapping(address => uint256)  internal balance;

    address constant KP_POOL_ADDRESS = address(0x01);
    address constant KPK_POOL_ADDRESS = address(0x01);
    address constant KPI_POOL_ADDRESS = address(0x01);

    mapping(address => address)  internal token_pool;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() public {
        balance[KP_POOL_ADDRESS] = TOKEN_COUNT;
        balance[KPK_POOL_ADDRESS] = TOKEN_COUNT;
        balance[KPI_POOL_ADDRESS] = TOKEN_COUNT;
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if(success){
            balance[token] = value;
        }
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function universalTransfer(
        address token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            safeTransfer(token, to, amount);
        }
    }

    function universalApproveMax(
        address token,
        address to,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                safeApprove(token, to, 0);
            }
            safeApprove(token, to, uint256(-1));
        }
    }

    function universalBalanceOf(address token, address who) internal view returns (uint256) {
            return IERC20(token).balanceOf(who);
    }

    function tokenBalanceOf(address token) internal view returns (uint256) {
        return balance[token];
    }

    
    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        return keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str));
    }

    //KP > KPK, KPK > KP, FISH > KPK, KP <> FISH, KPK <> FISH  
    function getSwapOrder(
        address tokenA,
        address tokenB
    ) internal  view returns (uint order){
        if (compareStr(IERC20(tokenA).name(),"KP") && compareStr(IERC20(tokenB).name(),"KPK")){
            order = 1;
        }
        else if (compareStr(IERC20(tokenA).name(),"KPK") && compareStr(IERC20(tokenB).name(),"KP")){   
            order = 2;
        }
        else if (compareStr(IERC20(tokenA).name(),"FISH") && compareStr(IERC20(tokenB).name(),"KPK")){    
            order = 3;
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 priceA,
        uint256 u_rate,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, "SwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        
        uint rate = getSwapOrder(tokenA, tokenB);
        ////KP > KPK=1, KPK > KP, FISH > KPK, KP <> FISH, KPK <> FISH  
        //KP > KPK ,FISH > KPK
        if(rate == 1 || rate == 3){  
            amountOut = amountIn.mul(priceA).mul(u_rate);
        }else if (rate == 2){   //KPK > KP 
            amountOut = amountIn.div(priceA).div(u_rate);
        }
        else {
            require(amountIn <= 0, "SwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        }
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 priceB,
        uint256 u_rate,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "SwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
       
        uint rate = getSwapOrder(tokenA, tokenB);
        //KP > KPK ,FISH > KPK
         if(rate == 1 || rate == 3){  
            amountIn = amountOut.div(priceB).div(u_rate);
        }else if (rate == 2){   //KPK > KP 
            amountIn = amountOut.mul(priceB).mul(u_rate);
        }
        else {
            require(amountOut <= 0, "SwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        }
    }


    // swaps an amount of either token given an external true price
    // true price is expressed in the ratio of token A to token B
    // caller must approve this contract to spend whichever token is intended to be swapped
    function swapToToken(
        address tokenA,
        address tokenB,
        uint256 amountIn,
        uint256 amountOut,
        address to
        // bool  isForward 
    ) public {
        require(amountIn > 0, 'ExampleSwapToPrice: ZERO_AMOUNT_IN');
        safeTransferFrom(tokenA, token_pool[tokenA], to, amountIn);
        balance[tokenA] -= amountIn;

        safeTransferFrom(tokenB,  to, token_pool[tokenB],amountOut);
        balance[tokenB] += amountOut;
    }
}
