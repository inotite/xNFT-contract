//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract XNft is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;

    struct ItemDetail {
        uint256 _id;
        string _name;
        string _message;
    }

    Counters.Counter private tokenIdCounter;

    IERC20 internal xyzToken;

    uint256 internal increaseScale;
    uint256 public currentFee;
    string public tokenUri;
    bool public contractLocked;

    mapping(uint256 => ItemDetail) private itemDetails;

    event XNftMinted(address indexed to, uint256 tokenId);

    function initialize(IERC20 _xyzToken) public initializer {
        __ERC721_init("xNFT", "xNFT");
        __ERC721Enumerable_init_unchained();
        __ERC721URIStorage_init_unchained();
        __Ownable_init_unchained();
        require(address(_xyzToken) != address(0), "token-not-zero-address");
        contractLocked = false;
        tokenUri = "https://clonex-assets.rtfkt.com/";
        // Making sure we start at token ID 1
        tokenIdCounter.increment();
        xyzToken = _xyzToken;
        setCurrentFee(100);
        setIncreaseScale(3);
    }

    function mintTransfer(
        address _to,
        string memory _name,
        string memory _message
    ) external {
        uint256 mintedId = tokenIdCounter.current();
        uint256 allowance = xyzToken.allowance(_to, address(this));
        require(allowance >= currentFee, "not allowed");
        bool success = xyzToken.transferFrom(_to, address(this), currentFee);
        require(success, "failed to transfer");
        currentFee = (currentFee * (100 + increaseScale)) / 100;

        _safeMint(_to, mintedId);
        tokenIdCounter.increment();

        itemDetails[mintedId]._id = mintedId;
        itemDetails[mintedId]._name = _name;
        itemDetails[mintedId]._message = _message;

        emit XNftMinted(_to, mintedId);
    }

    function tokensOfOwner(address _who)
        external
        view
        returns (ItemDetail[] memory)
    {
        uint256 tokenCount = balanceOf(_who);

        ItemDetail[] memory items = new ItemDetail[](tokenCount);

        for (uint256 index = 0; index < tokenCount; index++) {
            items[index] = itemDetails[tokenOfOwnerByIndex(_who, index)];
        }

        return (items);
    }

    function secureBaseUri(string memory newUri) public onlyOwner {
        require(
            contractLocked == false,
            "Contract has been locked and URI can't be changed"
        );
        tokenUri = newUri;
    }

    function lockContract() public onlyOwner {
        contractLocked = true;
    }

    /** OVERRIDES */
    function _baseURI() internal view override returns (string memory) {
        return tokenUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setCurrentFee(uint256 _fee) public onlyOwner {
        currentFee = _fee;
    }

    /**
     * _scale is percentage of increase rate
     */
    function setIncreaseScale(uint256 _scale) public onlyOwner {
        increaseScale = _scale;
    }

    function withdraw(address _to) public onlyOwner {
        uint256 balance = xyzToken.balanceOf(address(this));
        require(balance > 0, "balance is zero");

        bool success = xyzToken.transfer(_to, balance);
        require(success, "transfer failed");
    }
}
