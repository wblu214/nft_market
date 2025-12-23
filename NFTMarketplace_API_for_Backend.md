# NFT Marketplace 合约对接文档（Java / Spring Boot）

## 1. 合约基本信息

- **合约名称**：NFTMarketplace  
- **部署网络**：BSC 测试网（BSC Testnet）  
- **合约地址**：`0xCAD727e729e6737405773B05D2dac105a3026764`  
- **编译 Solidity 版本**：0.8.30  

该合约是一个 **结算型 NFT 交易合约（Settlement Layer）**，只负责：

- 保存最小必要的挂单信息（卖家、NFT 合约地址、tokenId、数量、价格、是否有效）  
- 校验 NFT 标准（ERC‑721 / ERC‑1155）和授权状态  
- 在买家支付 ETH 时执行「NFT 与 ETH 的原子交换」  
- 输出链上事件，供后端系统监听和做订单状态同步  

订单管理、并发控制、风控逻辑等全部在 **Java 后端** 实现，本合约只做最终的链上结算。

---

## 2. ABI（JSON）

> 后端可以直接复制下方 ABI，用于 Web3 库（如 Web3j、web3j‑quorum、web3j‑core 等）生成 Java 合约封装类。

```json
{
  "abi": [
    {
      "type": "function",
      "name": "buy",
      "inputs": [
        {
          "name": "listingId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [],
      "stateMutability": "payable"
    },
    {
      "type": "function",
      "name": "cancel",
      "inputs": [
        {
          "name": "listingId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "list",
      "inputs": [
        {
          "name": "nft",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "amount",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "price",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "listingId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "listings",
      "inputs": [
        {
          "name": "",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "seller",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "nft",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "amount",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "price",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "active",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "nextListingId",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "event",
      "name": "Cancelled",
      "inputs": [
        {
          "name": "listingId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "Listed",
      "inputs": [
        {
          "name": "listingId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        },
        {
          "name": "seller",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "nft",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "indexed": false,
          "internalType": "uint256"
        },
        {
          "name": "amount",
          "type": "uint256",
          "indexed": false,
          "internalType": "uint256"
        },
        {
          "name": "price",
          "type": "uint256",
          "indexed": false,
          "internalType": "uint256"
        }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "Sold",
      "inputs": [
        {
          "name": "listingId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        },
        {
          "name": "buyer",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        }
      ],
      "anonymous": false
    }
  ]
}
```

---

## 3. 合约功能说明（给后端同事看的）

### 3.1 外部函数

#### 3.1.1 `list`

- **函数签名**

  ```solidity
  function list(
      address nft,
      uint256 tokenId,
      uint256 amount,
      uint256 price
  ) external returns (uint256 listingId);
  ```

- **作用**：卖家将某个 NFT 挂单出售，生成一条链上订单（Listing）。

- **参数说明**
  - `nft`：NFT 合约地址（支持 ERC‑721 或 ERC‑1155，使用 ERC‑165 检测）。
  - `tokenId`：NFT 的 tokenId。
  - `amount`：
    - 对于 ERC‑721：必须为 `1`。
    - 对于 ERC‑1155：必须大于 `0`，表示出售的数量。
  - `price`：总价（单位：wei），买家在调用 `buy` 时必须支付的 ETH 数量。

- **返回值**
  - `listingId`：新创建订单的唯一 ID（从 1 开始自增）。

- **前置条件（需要由调用方保证）**
  - 调用者是 NFT 当前持有者：
    - ERC‑721：`ownerOf(tokenId) == msg.sender`
    - ERC‑1155：`balanceOf(msg.sender, tokenId) >= amount`
  - 合约已被授权：
    - ERC‑721：调用者先对本合约地址执行 `approve(tokenId)` 或 `setApprovalForAll`。
    - ERC‑1155：调用者对本合约地址执行 `setApprovalForAll`。
  - `price > 0`，`amount > 0`。

- **链上效果**
  - 在合约内部保存：
    - `seller, nft, tokenId, amount, price, active=true`
  - 触发 `Listed` 事件。

---

#### 3.1.2 `cancel`

- **函数签名**

  ```solidity
  function cancel(uint256 listingId) external;
  ```

- **作用**：卖家主动取消尚未成交的订单。

- **参数**
  - `listingId`：要取消的订单 ID。

- **前置条件**
  - 订单存在。
  - 订单当前处于 `active == true`。
  - 调用者必须是该订单的 `seller`。

- **链上效果**
  - 将该 listing 的 `active` 标记为 `false`。
  - 不会发生任何 NFT 或 ETH 转移。
  - 触发 `Cancelled` 事件。

---

#### 3.1.3 `buy`

- **函数签名**

  ```solidity
  function buy(uint256 listingId) external payable;
  ```

- **作用**：买家支付 ETH，完成 NFT 与资金的原子交换。

- **参数**
  - `listingId`：要购买的订单 ID。

- **前置条件**
  - 订单存在且 `active == true`。
  - `msg.value == price`（调用时支付的 ETH 数量必须等于订单价格）。

- **执行顺序（重要）**
  1. 校验订单存在、处于 active、`msg.value` 正确。
  2. 将订单 `active` 设为 `false`（防止重入和重复成交）。
  3. 从 `seller` 向 `buyer` 调用 NFT 合约的 `safeTransferFrom`：
     - 若为 ERC‑721：`safeTransferFrom(seller, buyer, tokenId)`。
     - 若为 ERC‑1155：`safeTransferFrom(seller, buyer, tokenId, amount, "")`。
  4. 将本次收到的 ETH 全额转给 `seller`。

- **链上效果**
  - NFT 所有权/余额变更。
  - ETH 从 `buyer` 转给 `seller`。
  - 订单变为 `active == false`，后续不能再购买。
  - 触发 `Sold` 事件。

---

#### 3.1.4 `listings`

- **函数签名**

  ```solidity
  function listings(uint256 listingId)
      external
      view
      returns (
          address seller,
          address nft,
          uint256 tokenId,
          uint256 amount,
          uint256 price,
          bool active
      );
  ```

- **作用**：根据 `listingId` 查询链上存储的订单详情。

- **使用场景**
  - 后端对订单进行状态校验。
  - 出问题时，对比链上和本地订单状态是否一致。

---

#### 3.1.5 `nextListingId`

- **函数签名**

  ```solidity
  function nextListingId() external view returns (uint256);
  ```

- **作用**：返回下一个将要分配的 `listingId`（当前最大 ID）。

- **使用场景**
  - 后端可以用这个值做一些 sanity check，或者在事件索引时知道当前可能的 ID 上限。

---

## 4. 事件说明（供后端监听）

### 4.1 `Listed`

```solidity
event Listed(
    uint256 indexed listingId,
    address indexed seller,
    address indexed nft,
    uint256 tokenId,
    uint256 amount,
    uint256 price
);
```

- 触发时机：成功调用 `list` 时。
- 关键字段：
  - `listingId`：订单 ID。
  - `seller`：卖家地址。
  - `nft`：NFT 合约地址。
  - `tokenId`：NFT tokenId。
  - `amount`：数量（ERC‑721 恒为 1，ERC‑1155 为出售数量）。
  - `price`：订单价格（wei）。

---

### 4.2 `Cancelled`

```solidity
event Cancelled(uint256 indexed listingId);
```

- 触发时机：成功调用 `cancel` 时。
- 关键字段：
  - `listingId`：被取消的订单 ID。

---

### 4.3 `Sold`

```solidity
event Sold(
    uint256 indexed listingId,
    address indexed buyer
);
```

- 触发时机：成功调用 `buy` 时。
- 关键字段：
  - `listingId`：成交订单 ID。
  - `buyer`：买家地址。

---
