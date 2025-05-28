// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// INTERFACE
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface Ivault {
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }


    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

contract Swapper {
    using SafeERC20 for IERC20;
    // burr bear vault
    Ivault public vault =   Ivault(0xBE09E71BDc7b8a50A05F7291920590505e3C7744);
    IERC20 nect         =   IERC20(0x1cE0a25D13CE4d52071aE7e02Cf1F6606F4C79d3);

    IERC20 usdc             = IERC20(0x549943e04f40284185054145c6E4e9568C1D3241);
    bytes32 public tri_id   = 0xd10e65a5f8ca6f835f2b1832e37cf150fb955f23000000000000000000000004;


    function nect_to_usdc(uint256 amount) external returns(uint256){
        nect.safeTransferFrom(msg.sender,address(this),amount);
        nect.safeIncreaseAllowance(address(vault), amount);
        uint256 amount_out = this._swap(address(nect), address(usdc), amount,tri_id);
        usdc.transfer(msg.sender, amount_out);
        return amount_out;
    }


    function swap(address asset,address iasset,bytes32 id,bytes32 iid, uint256 amount_in) external returns(uint256){
        
        // Transfert token depuis user vers ce contrat
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount_in);
        IERC20(iasset).safeTransferFrom(msg.sender, address(this), amount_in);

        // Approve Vault pour le montant à swapper
        IERC20(asset).safeIncreaseAllowance(address(vault), amount_in);
        IERC20(iasset).safeIncreaseAllowance(address(vault), amount_in);
        
        uint256 amount_out_1 = this._swap(asset,address(nect),amount_in,id);
        uint256 amount_out_2 = this._swap(iasset,address(nect),amount_in,iid);
        uint256 amount_out = amount_out_1+amount_out_2;
        
        nect.transfer(msg.sender,amount_out);
        return amount_out;
    }


    function _swap(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        bytes32 poolId
    ) public returns (uint256 amountOut) {

        Ivault.SingleSwap memory singleSwap = Ivault.SingleSwap({
            poolId: poolId,
            kind: Ivault.SwapKind.GIVEN_IN,
            assetIn: IAsset(assetIn),
            assetOut: IAsset(assetOut),
            amount: amountIn,
            userData: ""
        });

        Ivault.FundManagement memory funds = Ivault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        uint256 limit = 0;
        uint256 deadline = block.timestamp; 

        amountOut = vault.swap(singleSwap, funds, limit, deadline);
        return amountOut;
    }
}
