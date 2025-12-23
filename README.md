# NFT Marketplace MVP 产品需求文档（PRD）

## 1. 文档目的

本文档用于**指导智能合约工程师实现 NFT Marketplace 的最小可行版本（MVP）合约**。

该合约将作为**链上结算层（Settlement Layer）**存在：

* 负责 NFT 的最终转移
* 负责资金（ETH）的最终结算
* 不承载复杂交易逻辑、风控或业务状态

链下交易流程、订单管理、并发控制由 **Java 后端系统负责**。

---

## 2. 设计原则

### 2.1 核心原则

* **最小职责原则（Minimal Responsibility）**
  合约只负责不可逆的链上行为

* **标准优先**
  严格遵循 ERC721 / ERC1155 / ERC165 标准

* **安全优先**
  防重入、状态先行更新、失败可回滚

* **可扩展但不实现**
  为未来功能预留结构，但本版本不实现

---

## 3. MVP 范围定义

### 3.1 本版本必须支持（In Scope）

* ERC721 NFT 交易
* ERC1155 NFT 交易
* NFT 上架（List）
* NFT 下架（Cancel）
* NFT 购买（Buy）
* ETH 结算
* 事件（Event）输出

---

## 4. 系统角色说明

| 角色             | 说明                 |
| -------------- | ------------------ |
| 卖家（Seller）     | NFT 当前持有者          |
| 买家（Buyer）      | 支付 ETH 购买 NFT      |
| Marketplace 合约 | 执行 NFT 与 ETH 的原子交换 |
| Java 后端        | 负责订单、并发、风控（非合约职责）  |

---

## 5. 合约职责边界（非常重要）

### 5.1 合约需要做的事

* 校验 NFT 标准类型（ERC721 / ERC1155）
* 校验 NFT 授权状态
* 保存最小订单信息
* 执行 NFT 转移
* 执行 ETH 转账
* 输出交易事件

## 6. 数据结构设计（合约侧）

### 6.1 Listing（订单结构）

每一条链上订单表示一个**可被结算的 NFT 出售意图**。

包含以下信息：

* 卖家地址（seller）
* NFT 合约地址（nft）
* tokenId（ERC721 / ERC1155 通用）
* 数量（amount，仅 ERC1155 使用，ERC721 固定为 1）
* 价格（price，单位：wei）
* 是否有效（active）

设计要求：

* ERC721：amount 必须为 1
* ERC1155：amount > 0

---

## 7. 功能需求（Functional Requirements）

### 7.1 NFT 上架（List）

#### 功能描述

卖家将 NFT 挂单出售，生成一条链上 Listing。

#### 前置条件

* 调用者必须是 NFT 的实际持有者
* Marketplace 合约已被授权：

  * ERC721：approve
  * ERC1155：setApprovalForAll

#### 功能要求

* 校验 price > 0
* 校验 NFT 支持 ERC721 或 ERC1155（ERC165）
* 校验 NFT 所有权
* 校验授权状态
* 创建 Listing 并标记为 active

#### 成功结果

* 返回唯一 listingId
* 触发 Listed 事件

---

### 7.2 NFT 下架（Cancel）

#### 功能描述

卖家主动取消尚未成交的订单。

#### 前置条件

* Listing 必须存在
* Listing 状态为 active
* 调用者必须是 seller

#### 功能要求

* 将 Listing 标记为 inactive
* 不进行任何 NFT 或 ETH 转移

#### 成功结果

* 触发 Cancelled 事件

---

### 7.3 NFT 购买（Buy）

#### 功能描述

买家支付 ETH，完成 NFT 与资金的原子交换。

#### 前置条件

* Listing 存在且 active
* msg.value 必须等于 Listing.price

#### 核心执行顺序（强制要求）

1. 校验 Listing 有效性
2. 将 Listing 标记为 inactive（防重入）
3. 执行 NFT 转移（seller → buyer）
4. 执行 ETH 转账（buyer → seller）

#### 安全要求

* 必须防止重入攻击
* 状态更新必须先于外部调用

#### 成功结果

* NFT 成功转移
* ETH 成功结算
* 触发 Sold 事件

---

## 8. NFT 标准兼容要求

### 8.1 ERC721 支持要求

* 使用 safeTransferFrom
* amount 固定为 1

### 8.2 ERC1155 支持要求

* 使用 safeTransferFrom
* 支持指定数量转移

### 8.3 标准识别

* 使用 ERC165 判断接口支持情况
* 若不支持 ERC721 / ERC1155，交易必须失败

---

## 9. 事件（Events）需求

合约必须完整输出以下事件，用于 Java 后端监听和索引。

### 9.1 Listed

* listingId
* seller
* nft
* tokenId
* amount
* price

### 9.2 Cancelled

* listingId

### 9.3 Sold

* listingId
* buyer

---

## 10. 安全与风控要求

### 10.1 必须实现

* 重入防护（Reentrancy Guard 或等效逻辑）
* Checks-Effects-Interactions 模式
* 严格参数校验

### 10.2 明确假设

* Java 后端已处理并发与风控
* 合约不对链下状态负责

---

## 11. 与 Java 后端的协作边界

### 合约是：

* 最终真相来源（Source of Truth）
* 原子结算执行者

### Java 后端是：

* 交易流程管理者
* 订单状态维护者
* 并发与幂等控制者

合约**不依赖后端正确性**，但后端依赖合约事件作为最终确认。

---

## 12. 可扩展性说明（本期不实现）

以下能力需在设计中考虑，但**不在本期实现范围**：

* 版税（ERC2981）
* 平台手续费
* ERC20 支付
* Off-chain 订单签名
* 可升级代理模式

---

## 13. 验收标准（Acceptance Criteria）

* ERC721 与 ERC1155 均可成功完成上架、购买
* 非法 NFT / 非授权操作必须失败
* 所有状态变化必须有事件输出
* 不得出现双花或重复成交

---

## 14. 总结

本 PRD 定义的是一个**结算型 Marketplace 合约**：

* 功能极简
* 职责清晰
* 易于审计
* 适合企业级系统作为链上基础模块

该合约将作为整个 NFT 交易系统中**最稳定、最少改动的一层**长期存在。
