// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// INTERFACE
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITwin {
    function mintAssets(string calldata _symbol, uint256 _amount) external;
    function burnAssets(string calldata _symbol,uint256 _amount) external;
    function getUpperLimit(string calldata _symbol)external view returns(uint256);
}

contract Minter {

    using SafeERC20 for IERC20;

    ITwin twin  = ITwin(0xF77B36ba4691c5e3e022D9e7b5a8f78103ccC57a);

    IERC20 usdc = IERC20(0x549943e04f40284185054145c6E4e9568C1D3241);
    
    // fonction d'estimation

    function getMintAmount(string memory name, uint256 amount) public view returns(uint256){
        uint256 up = twin.getUpperLimit(name);
        return uint256(amount/up);
    }
    
    function getRedeemAmount(string memory name, uint256 amount) public view returns(uint256){
        uint256 up = twin.getUpperLimit(name);
        return uint256(up/amount * 98/100);
    }
    
    function mint(string memory name,address asset,address iasset,uint256 amount) external returns(uint256){
        require(usdc.balanceOf(msg.sender) == amount,"mint error");
        usdc.safeTransferFrom(msg.sender,address(this),amount);
        usdc.safeIncreaseAllowance(address(twin), amount);
        twin.mintAssets(name, amount);
        uint256 amount_out = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transfer(msg.sender,amount_out);
        IERC20(iasset).transfer(msg.sender,amount_out);
        return amount_out;
    }

    function burn(string memory name,address _asset,address _iasset,uint256 amount) external returns(uint256){
        IERC20 asset = IERC20(_asset);
        asset.safeTransferFrom(msg.sender,address(this),amount);
        IERC20 iasset = IERC20(_iasset);
        iasset.safeTransferFrom(msg.sender,address(this),amount);
        asset.approve(address(twin), amount);
        iasset.approve(address(twin), amount);
        twin.burnAssets(name, amount);
        uint256 bal = usdc.balanceOf(address(this));
        usdc.transfer(msg.sender,bal);
        return bal;
    }
}
