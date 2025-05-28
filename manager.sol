// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./swapper.sol";
import "./minter.sol";

error InsufficientBalance(uint256 balance, uint256 required);

interface IERC3156FlashLender {
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IERC3156FlashBorrower {
    // Signature EXACTE obligatoire ici
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

contract Manager is IERC3156FlashBorrower {

    address public owner;


    struct Asset {
        string name;
        address assets;
        address iassets;
        address pool;
        address ipool;
        address stable;
        address swapper;
    }

    Asset[] Assets;

    function addAssets(bytes memory datas) external {
        (string memory name,address assets,address iassets,address pool,address ipool,address stable,address swapper) = 
                abi.decode(datas, (string,address,address,address,address,address,address));
        Asset memory asset =  Asset(name,assets,iassets,pool,ipool,stable,swapper);
        Assets.push(asset);
    }

    // flash loan de nect
    IERC3156FlashLender public lender = IERC3156FlashLender(0x1cE0a25D13CE4d52071aE7e02Cf1F6606F4C79d3);
    
    IERC20 public nect = IERC20(0x1cE0a25D13CE4d52071aE7e02Cf1F6606F4C79d3);
    IERC20 public usdc = IERC20(0x549943e04f40284185054145c6E4e9568C1D3241);
    
    // ici je pense que je vais faire une collection de swapper

    Swapper public swapper;
    Minter public minter;

    constructor() {
        owner = msg.sender;
        swapper = new Swapper();
        minter = new Minter();
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function exec(uint256 amount, bytes calldata data) external  {
        lender.flashLoan(IERC3156FlashBorrower(address(this)), address(nect), amount, data);
        uint256 bal = nect.balanceOf(address(this));
        if (bal > 0){
            nect.transfer(owner,bal);
        }

    }

    // Implémentation correcte de la fonction onFlashLoan
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), "Not lender");
        require(initiator == address(this), "Not initiator");
        require(token == address(nect), "Token mismatch");

        // d'abord swapper nect en usd en minter et ensuite reswapper 
        
        nect.approve(address(swapper), amount);
        uint256 usdc_amount = swapper.nect_to_usdc(amount);

        // Exemple de décodage des données passées
        (string memory name, address asset, address iasset, bytes32 id, bytes32 iid) =
                         abi.decode(data, (string,address,address,bytes32,bytes32));

        usdc.approve(address(minter),usdc_amount);

        uint256 mintedAmount = minter.mint(name, asset, iasset, usdc_amount);

        IERC20(asset).approve(address(swapper), mintedAmount);
        IERC20(iasset).approve(address(swapper), mintedAmount);
        swapper.swap(asset, iasset, id, iid, mintedAmount);

        uint256 totalDebt = amount + fee;

        if (nect.balanceOf(address(this)) < totalDebt) {
            revert InsufficientBalance(nect.balanceOf(address(this)), totalDebt);
        }
        nect.approve(address(lender), totalDebt);
        // Tu peux renvoyer ce hash pour signaler le succès
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
