pragma solidity 0.4.18;


import "./Utils.sol";


contract Utils2 is Utils {

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) {
            return user.balance;
        } else {
            return token.balanceOf(user);
        }
    }

    function getDecimalsSafe(ERC20 token) internal returns(uint) {

        if (decimals[token] == 0) {
            setDecimals(token);
        }

        return decimals[token];
    }

    /* solhint-disable no-inline-assembly */
    // some tokens don't support decimal API. we will try to get decimals using assembly and low level calls.
    // if it fails we avoid revert and just use 18 for this token.
    /// @dev notice, overrides previous implementation.
    function setDecimals(ERC20 token) internal {
        uint decimal;

        if (token == ETH_TOKEN_ADDRESS) {
            decimal = ETH_DECIMALS;
        } else {
            uint[1] memory value;

            if (!address(token).call(bytes4(keccak256("decimals()")))) {/* solhint-disable-line avoid-low-level-calls */
              //above code can only be performed with low level call. otherwise operation will revert. disable solhint.
                // call failed
                decimal = 18;
            } else {
                assembly {
                    returndatacopy(value, 0, returndatasize)
                }
                decimal = value[0];
            }
        }

        decimals[token] = decimal;
    }
    /* solhint-enable no-inline-assembly */

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }
}
