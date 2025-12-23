# ProjectNFT & Project1155 合约对接文档（后端调用说明）

## 1. 合约基本信息

### 1.1 ProjectNFT（ERC721）

- 合约名称：`ProjectNFT`
- 标准：ERC721 + ERC721Metadata
- 合约地址：`0xaa6a15D595bA8F69680465FBE61d9d886057Cb1E`
- 作用：单份 NFT（1-of-1），每个 `tokenId` 只代表一份独立藏品。
- 特点：mint 完全开放，任何地址都可以铸造自己的 ERC721 NFT。

---

### 1.2 Project1155（ERC1155）

- 合约名称：`Project1155`
- 标准：ERC1155
- 合约地址：`0x1fF53616471271d80E17BD2A46C863d3Fd38aE81`
- 作用：多份 NFT（semi-fungible），同一个 `id` 可以有多份。
- 特点：mint 完全开放，任何地址都可以为某个 `id` 铸造多份 ERC1155 NFT。

---

## 2. ProjectNFT（ERC721）ABI

> 该合约用于「单份」NFT（例如头像、艺术品），每次 mint 生成一个新的唯一 `tokenId`。

```json
{
  "abi": [
    {
      "type": "constructor",
      "inputs": [
        { "name": "name_", "type": "string", "internalType": "string" },
        { "name": "symbol_", "type": "string", "internalType": "string" }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "approve",
      "inputs": [
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "balanceOf",
      "inputs": [
        { "name": "owner_", "type": "address", "internalType": "address" }
      ],
      "outputs": [
        { "name": "", "type": "uint256", "internalType": "uint256" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getApproved",
      "inputs": [
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [
        { "name": "", "type": "address", "internalType": "address" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "isApprovedForAll",
      "inputs": [
        { "name": "owner_", "type": "address", "internalType": "address" },
        { "name": "operator", "type": "address", "internalType": "address" }
      ],
      "outputs": [
        { "name": "", "type": "bool", "internalType": "bool" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "mint",
      "inputs": [
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "uri", "type": "string", "internalType": "string" }
      ],
      "outputs": [
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "name",
      "inputs": [],
      "outputs": [
        { "name": "", "type": "string", "internalType": "string" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "nextTokenId",
      "inputs": [],
      "outputs": [
        { "name": "", "type": "uint256", "internalType": "uint256" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "ownerOf",
      "inputs": [
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [
        { "name": "", "type": "address", "internalType": "address" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "safeTransferFrom",
      "inputs": [
        { "name": "from", "type": "address", "internalType": "address" },
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "safeTransferFrom",
      "inputs": [
        { "name": "from", "type": "address", "internalType": "address" },
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" },
        { "name": "", "type": "bytes", "internalType": "bytes" }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "setApprovalForAll",
      "inputs": [
        { "name": "operator", "type": "address", "internalType": "address" },
        { "name": "approved", "type": "bool", "internalType": "bool" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "supportsInterface",
      "inputs": [
        { "name": "interfaceId", "type": "bytes4", "internalType": "bytes4" }
      ],
      "outputs": [
        { "name": "", "type": "bool", "internalType": "bool" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "symbol",
      "inputs": [],
      "outputs": [
        { "name": "", "type": "string", "internalType": "string" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "tokenURI",
      "inputs": [
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [
        { "name": "", "type": "string", "internalType": "string" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "transferFrom",
      "inputs": [
        { "name": "from", "type": "address", "internalType": "address" },
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "event",
      "name": "Approval",
      "inputs": [
        { "name": "_owner", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_approved", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_tokenId", "type": "uint256", "indexed": true, "internalType": "uint256" }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "ApprovalForAll",
      "inputs": [
        { "name": "_owner", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_operator", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_approved", "type": "bool", "indexed": false, "internalType": "bool" }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "Transfer",
      "inputs": [
        { "name": "_from", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_to", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_tokenId", "type": "uint256", "indexed": true, "internalType": "uint256" }
      ],
      "anonymous": false
    }
  ]
}
```

---

## 3. Project1155（ERC1155）ABI

> 该合约用于「多份」NFT（例如门票、游戏道具），同一个 `id` 可以铸造多份。

```json
{
  "abi": [
    {
      "type": "constructor",
      "inputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "balanceOf",
      "inputs": [
        { "name": "account", "type": "address", "internalType": "address" },
        { "name": "id", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [
        { "name": "", "type": "uint256", "internalType": "uint256" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "balanceOfBatch",
      "inputs": [
        { "name": "accounts", "type": "address[]", "internalType": "address[]" },
        { "name": "ids", "type": "uint256[]", "internalType": "uint256[]" }
      ],
      "outputs": [
        { "name": "balances", "type": "uint256[]", "internalType": "uint256[]" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "isApprovedForAll",
      "inputs": [
        { "name": "account", "type": "address", "internalType": "address" },
        { "name": "operator", "type": "address", "internalType": "address" }
      ],
      "outputs": [
        { "name": "", "type": "bool", "internalType": "bool" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "mint",
      "inputs": [
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "id", "type": "uint256", "internalType": "uint256" },
        { "name": "amount", "type": "uint256", "internalType": "uint256" },
        { "name": "newUri", "type": "string", "internalType": "string" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "safeBatchTransferFrom",
      "inputs": [
        { "name": "from", "type": "address", "internalType": "address" },
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "ids", "type": "uint256[]", "internalType": "uint256[]" },
        { "name": "values", "type": "uint256[]", "internalType": "uint256[]" },
        { "name": "", "type": "bytes", "internalType": "bytes" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "safeTransferFrom",
      "inputs": [
        { "name": "from", "type": "address", "internalType": "address" },
        { "name": "to", "type": "address", "internalType": "address" },
        { "name": "id", "type": "uint256", "internalType": "uint256" },
        { "name": "value", "type": "uint256", "internalType": "uint256" },
        { "name": "", "type": "bytes", "internalType": "bytes" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "setApprovalForAll",
      "inputs": [
        { "name": "operator", "type": "address", "internalType": "address" },
        { "name": "approved", "type": "bool", "internalType": "bool" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "supportsInterface",
      "inputs": [
        { "name": "interfaceId", "type": "bytes4", "internalType": "bytes4" }
      ],
      "outputs": [
        { "name": "", "type": "bool", "internalType": "bool" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "uri",
      "inputs": [
        { "name": "id", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [
        { "name": "", "type": "string", "internalType": "string" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "event",
      "name": "ApprovalForAll",
      "inputs": [
        { "name": "_owner", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_operator", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_approved", "type": "bool", "indexed": false, "internalType": "bool" }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "TransferBatch",
      "inputs": [
        { "name": "_operator", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_from", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_to", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_ids", "type": "uint256[]", "indexed": false, "internalType": "uint256[]" },
        { "name": "_values", "type": "uint256[]", "indexed": false, "internalType": "uint256[]" }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "TransferSingle",
      "inputs": [
        { "name": "_operator", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_from", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_to", "type": "address", "indexed": true, "internalType": "address" },
        { "name": "_id", "type": "uint256", "indexed": false, "internalType": "uint256" },
        { "name": "_value", "type": "uint256", "indexed": false, "internalType": "uint256" }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "URI",
      "inputs": [
        { "name": "_value", "type": "string", "indexed": false, "internalType": "string" },
        { "name": "_id", "type": "uint256", "indexed": true, "internalType": "uint256" }
      ],
      "anonymous": false
    }
  ]
}
```

---

## 4. 常见调用场景说明（简要）

> 这里只说明参数语义，具体用什么 Web3 库、如何在 Java/Spring Boot 里集成，由后端自由选择。

### 4.1 ProjectNFT（ERC721）mint 流程

- 函数：`mint(address to, string uri)`
- 行为：
  - 为 `to` 地址铸造一个新的 ERC721 NFT。
  - `tokenId` 为自增 ID，返回值即新生成的 `tokenId`。
  - `uri` 是元数据链接（通常为 IPFS/HTTP URL），前端可以根据业务传入。

---

### 4.2 Project1155（ERC1155）mint 流程

- 函数：`mint(address to, uint256 id, uint256 amount, string newUri)`
- 行为：
  - 为 `to` 地址铸造 `amount` 份 `id` 对应的 ERC1155 代币。
  - 若这是该 `id` 第一次设置 URI 且 `newUri` 非空，则记录元数据并触发 `URI` 事件。

---

### 4.3 与 Marketplace 的协作（说明）

- 铸造完成后，用户需要对 Marketplace 合约进行授权：
  - ERC721：`setApprovalForAll(marketplaceAddress, true)` 或对单个 `tokenId` 执行 `approve`。
  - ERC1155：`setApprovalForAll(marketplaceAddress, true)`。
- 然后调用 `NFTMarketplace.list(...)` 完成上架，后续由 `NFTMarketplace.buy(...)` 完成交易结算。

