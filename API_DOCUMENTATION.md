# Finmate API Documentation

**Version**: 1.0.0  
**Base URL**: `http://localhost:8080`  
**Swagger UI**: http://localhost:8080/swagger-ui.html

---

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Authentication](#authentication)
4. [API Endpoints](#api-endpoints)
   - [Auth API](#1-authentication-api)
   - [Wallets API](#2-wallets-api)
   - [Categories API](#3-categories-api)
   - [Transactions API](#4-transactions-api)
   - [Budgets API](#5-budgets-api-zbb-spending-budget)
   - [Savings Goals API](#6-savings-goals-api-zbb-savings-fund)
   - [User Settings API](#7-user-settings-api)
   - [Dashboard API](#8-dashboard-api-zbb-analytics)
5. [Business Logic](#business-logic)
6. [Error Handling](#error-handling)
7. [Common Use Cases](#common-use-cases)

---

## Introduction

**Finmate Smart Money Management** is a personal finance application based on the **Zero-Based Budgeting (ZBB)** methodology. This API provides backend services for:

- ✅ Multi-wallet management (Cash, Bank accounts, E-wallets)
- ✅ Transaction tracking with auto balance updates
- ✅ Zero-Based Budgeting with real-time spending tracking
- ✅ Savings goals with progress monitoring
- ✅ Financial analytics and dashboard metrics

**Key Principle**: Every dollar has a job. Track where your money is (Wallets) and assign every dollar to a specific purpose (Budgets or Savings Goals).

---

## Architecture Overview

### Core Entities

```
User
├── Wallets (Money Storage Locations)
│   └── Transactions (Money Movement)
├── Categories (Spending/Income Types)
├── Budgets (Spending Plans per Category)
└── Savings Goals (Long-term Savings Buckets)
```

### Data Flow

```
1. Income Transaction → Increases Wallet Balance
2. User Assigns Money → Creates Budget (with limit)
3. Expense Transaction → Decreases Wallet + Decreases Budget Available
4. Savings Commit → Decreases Wallet + Increases Savings Goal
```

---

## Authentication

### Current Implementation
All endpoints (except `/api/auth/*`) require this header:
```http
User-Id: <UUID>
```

**Example**:
```http
GET /api/wallets
User-Id: 123e4567-e89b-12d3-a456-426614174000
```

> **Note**: JWT authentication with Bearer tokens will be implemented in future versions.

### Security Features
- ✅ Password hashing with BCrypt (strength 10)
- ❌ JWT tokens (planned)
- ❌ Refresh tokens (planned)

---

## API Endpoints

## 1. Authentication API

### 1.1. Register New User

Creates a new user account with email and password.

**Endpoint**: `POST /api/auth/register`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "fullName": "Nguyen Van A"
}
```

**Field Validations**:
- `email`: Valid email format, unique
- `password`: Minimum 6 characters (hashed with BCrypt)
- `fullName`: Non-empty string

**Response** `201 Created`:
```json
{
  "userId": "123e4567-e89b-12d3-a456-426614174000",
  "email": "user@example.com",
  "fullName": "Nguyen Van A",
  "token": "mock-jwt-token"
}
```

**What Happens**:
1. Password is hashed using BCrypt
2. User record created in database
3. Default UserSettings created automatically
4. Returns user info + mock token

---

### 1.2. Login

Authenticates user with email and password.

**Endpoint**: `POST /api/auth/login`

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response** `200 OK`:
```json
{
  "userId": "123e4567-e89b-12d3-a456-426614174000",
  "email": "user@example.com",
  "fullName": "Nguyen Van A",
  "token": "mock-jwt-token"
}
```

**Errors**:
- `401 Unauthorized`: Invalid email or password

---

## 2. Wallets API

Wallets represent **where your money is stored** (Cash, Bank Account, MoMo, etc.). They are NOT spending categories.

### 2.1. Create Wallet

**Endpoint**: `POST /api/wallets`

**Headers**:
```http
User-Id: <UUID>
Content-Type: application/json
```

**Request Body**:
```json
{
  "name": "Tiền Mặt",
  "balance": 5000000,
  "currency": "VND",
  "icon": "cash"
}
```

**Field Descriptions**:
- `name`: Wallet name (e.g., "Cash", "Vietcombank", "MoMo")
- `balance`: Initial balance in smallest currency unit
- `currency`: Currency code (`VND`, `USD`)
- `icon`: Icon identifier for UI

**Response** `201 Created`:
```json
{
  "id": 1,
  "name": "Tiền Mặt",
  "balance": 5000000.00,
  "currency": "VND",
  "icon": "cash"
}
```

---

### 2.2. Get All Wallets

Returns all wallets for the authenticated user with current balances.

**Endpoint**: `GET /api/wallets`

**Headers**:
```http
User-Id: <UUID>
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "name": "Tiền Mặt",
    "balance": 5000000.00,
    "currency": "VND",
    "icon": "cash"
  },
  {
    "id": 2,
    "name": "Vietcombank",
    "balance": 10000000.00,
    "currency": "VND",
    "icon": "bank"
  }
]
```

**Use Case**: Display wallet summary on home screen.

---

### 2.3. Get Wallet by ID

**Endpoint**: `GET /api/wallets/{id}`

**Response** `200 OK`: Same as single wallet object above

**Errors**:
- `404 Not Found`: Wallet does not exist

---

### 2.4. Update Wallet

Updates wallet information (name, balance, currency, icon).

**Endpoint**: `PUT /api/wallets/{id}`

**Request Body**: Same as Create Wallet

**Response** `200 OK`: Updated wallet object

> ⚠️ **Warning**: Manually updating balance is NOT recommended. Use Transactions instead to maintain audit trail.

---

### 2.5. Delete Wallet

Deletes a wallet from the system.

**Endpoint**: `DELETE /api/wallets/{id}`

**Response**: `204 No Content`

> 💡 **Recommendation**: Implement soft delete to preserve transaction history.

---

## 3. Categories API

Categories classify transactions as INCOME or EXPENSE (e.g., "Salary", "Food", "Transportation").

### Category Types
- `INCOME`: Salary, Bonus, Freelance
- `EXPENSE`: Food, Rent, Transportation

### System vs Custom Categories
- **System Categories**: Pre-defined, cannot be deleted
- **Custom Categories**: User-created, can be modified/deleted

---

### 3.1. Create Category

**Endpoint**: `POST /api/categories`

**Headers**:
```http
User-Id: <UUID>
Content-Type: application/json
```

**Request Body**:
```json
{
  "name": "Ăn uống",
  "type": "EXPENSE",
  "icon": "food"
}
```

**Field Descriptions**:
- `name`: Category name
- `type`: `INCOME` or `EXPENSE`
- `icon`: Icon identifier

**Response** `201 Created`:
```json
{
  "id": 1,
  "name": "Ăn uống",
  "type": "EXPENSE",
  "icon": "food",
  "isSystemCategory": false
}
```

---

### 3.2. Get All Categories

Returns all categories (system + custom) for the user.

**Endpoint**: `GET /api/categories`

**Query Parameters**:
- `type` (optional): Filter by `INCOME` or `EXPENSE`

**Example**:
```http
GET /api/categories?type=EXPENSE
User-Id: <UUID>
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "name": "Lương",
    "type": "INCOME",
    "icon": "salary",
    "isSystemCategory": true
  },
  {
    "id": 2,
    "name": "Ăn uống",
    "type": "EXPENSE",
    "icon": "food",
    "isSystemCategory": false
  }
]
```

---

### 3.3. Get System Categories

Returns only pre-defined system categories.

**Endpoint**: `GET /api/categories/system`

**Response** `200 OK`: Array of categories with `isSystemCategory: true`

---

### 3.4. Get Category by ID

**Endpoint**: `GET /api/categories/{id}`

**Response** `200 OK`: Single category object

---

### 3.5. Update Category

**Endpoint**: `PUT /api/categories/{id}`

**Request Body**: Same as Create Category

**Response** `200 OK`: Updated category

> ⚠️ **Note**: System categories cannot be updated.

---

### 3.6. Delete Category

**Endpoint**: `DELETE /api/categories/{id}`

**Response**: `204 No Content`

> ⚠️ **Note**: System categories cannot be deleted.

---

## 4. Transactions API

Transactions are the **single source of truth** for all money movements. Every transaction automatically updates wallet balances and budget tracking.

### Transaction Types

| Type | Description | Affects |
|------|-------------|---------|
| `INCOME` | Money coming in | Wallet (+) |
| `EXPENSE` | Money going out | Wallet (-), Budget Available (-) |
| `TRANSFER` | Move money between wallets | From Wallet (-), To Wallet (+) |
| `SAVINGS_COMMIT` | Commit to savings goal | Wallet (-), Savings Goal (+) |
| `INVESTMENT_EXECUTION` | Execute investment | Wallet (-), Investment Plan (+) |

---

### 4.1. Create Transaction - EXPENSE

Records a spending transaction.

**Endpoint**: `POST /api/transactions`

**Headers**:
```http
User-Id: <UUID>
Content-Type: application/json
```

**Request Body**:
```json
{
  "walletId": 1,
  "categoryId": 2,
  "type": "EXPENSE",
  "amount": 50000,
  "note": "Ăn trưa với đồng nghiệp",
  "transactionDate": "2026-02-02T12:30:00",
  "imageUrl": "https://res.cloudinary.com/finmate/receipt.jpg"
}
```

**Field Descriptions**:
- `walletId`: Which wallet to deduct from
- `categoryId`: Transaction category (must be EXPENSE type)
- `type`: Transaction type
- `amount`: Amount in smallest currency unit (VND, cents)
- `note`: Optional description
- `transactionDate`: ISO 8601 datetime
- `imageUrl`: Optional receipt image URL

**Response** `201 Created`:
```json
{
  "id": 1,
  "walletId": 1,
  "walletName": "Tiền Mặt",
  "categoryId": 2,
  "categoryName": "Ăn uống",
  "type": "EXPENSE",
  "amount": 50000.00,
  "note": "Ăn trưa với đồng nghiệp",
  "transactionDate": "2026-02-02T12:30:00",
  "imageUrl": "https://res.cloudinary.com/finmate/receipt.jpg",
  "toWalletId": null,
  "toWalletName": null,
  "savingsGoalId": null,
  "savingsGoalName": null,
  "investmentPlanId": null,
  "investmentPlanName": null
}
```

**What Happens**:
1. ✅ Wallet balance decreases by 50,000
2. ✅ If a budget exists for "Ăn uống", its `spent` increases
3. ✅ Budget's `available` decreases automatically
4. ✅ Transaction is saved with timestamp

**Errors**:
- `400 Bad Request`: Insufficient balance in wallet
- `404 Not Found`: Wallet or Category not found

---

### 4.2. Create Transaction - INCOME

Records an income transaction.

**Request Body**:
```json
{
  "walletId": 1,
  "categoryId": 1,
  "type": "INCOME",
  "amount": 15000000,
  "note": "Lương tháng 2",
  "transactionDate": "2026-02-01T09:00:00"
}
```

**What Happens**:
1. ✅ Wallet balance increases by 15,000,000
2. ✅ Total income for the month increases
3. 💡 User should now assign this money to budgets (ZBB principle)

---

### 4.3. Create Transaction - TRANSFER

Moves money between wallets (e.g., withdraw cash from bank).

**Request Body**:
```json
{
  "walletId": 2,
  "toWalletId": 1,
  "type": "TRANSFER",
  "amount": 1000000,
  "note": "Rút tiền từ Vietcombank",
  "transactionDate": "2026-02-02T14:00:00"
}
```

**Field Descriptions**:
- `walletId`: Source wallet (money leaves from here)
- `toWalletId`: Destination wallet (money goes here)
- `categoryId`: Not required for TRANSFER

**What Happens** (Atomic Operation):
1. ✅ Source wallet (Vietcombank) balance decreases by 1,000,000
2. ✅ Destination wallet (Tiền Mặt) balance increases by 1,000,000
3. ✅ If error occurs, both changes are rolled back

**Errors**:
- `400 Bad Request`: Insufficient balance in source wallet
- `400 Bad Request`: Cannot transfer to the same wallet

---

### 4.4. Create Transaction - SAVINGS_COMMIT

Commits money to a savings goal (ZBB Savings Fund).

**Request Body**:
```json
{
  "walletId": 1,
  "savingsGoalId": 1,
  "type": "SAVINGS_COMMIT",
  "amount": 500000,
  "note": "Tiết kiệm mua iPhone",
  "transactionDate": "2026-02-02T15:00:00"
}
```

**Field Descriptions**:
- `savingsGoalId`: Target savings goal
- `categoryId`: Not required for SAVINGS_COMMIT

**What Happens**:
1. ✅ Wallet balance decreases by 500,000
2. ✅ Savings goal `currentAmount` increases by 500,000
3. ✅ Savings goal `percentageAchieved` recalculated

---

### 4.5. Get Transaction by ID

**Endpoint**: `GET /api/transactions/{id}`

**Response** `200 OK`: Single transaction object

---

### 4.6. Get All Transactions

Returns all transactions for the user, ordered by date (newest first).

**Endpoint**: `GET /api/transactions`

**Headers**:
```http
User-Id: <UUID>
```

**Response** `200 OK`: Array of transaction objects

---

### 4.7. Filter Transactions

Filters transactions by wallet, category, and date range.

**Endpoint**: `GET /api/transactions/filter`

**Query Parameters** (all optional):
- `walletId`: Filter by wallet ID
- `categoryId`: Filter by category ID
- `startDate`: ISO datetime (inclusive)
- `endDate`: ISO datetime (inclusive)

**Example**:
```http
GET /api/transactions/filter?walletId=1&startDate=2026-02-01T00:00:00&endDate=2026-02-28T23:59:59
User-Id: <UUID>
```

**Use Case**: Get all transactions from "Tiền Mặt" wallet in February 2026.

---

### 4.8. Delete Transaction

Deletes a transaction (hard delete).

**Endpoint**: `DELETE /api/transactions/{id}`

**Response**: `204 No Content`

> ⚠️ **Important**: Deleting a transaction will:
> - Reverse wallet balance changes
> - Reverse budget spent/available changes
> - Reverse savings goal progress
>
> 💡 **Recommendation**: Implement soft delete and reversal transaction instead.

---

## 5. Budgets API (ZBB Spending Budget)

Budgets represent **spending plans** for each category with a defined limit. They track how much you've spent vs. how much you planned to spend.

### Zero-Based Budgeting Concept
Every dollar of income gets assigned to a budget category until income = budgets. This ensures you "give every dollar a job."

---

### 5.1. Create Budget

Creates a spending budget for a category.

**Endpoint**: `POST /api/budgets`

**Headers**:
```http
User-Id: <UUID>
Content-Type: application/json
```

**Request Body**:
```json
{
  "categoryId": 2,
  "amountLimit": 3000000,
  "period": "MONTH"
}
```

**Field Descriptions**:
- `categoryId`: Category to budget for (must be EXPENSE type)
- `amountLimit`: Maximum spending limit for this period
- `period`: `WEEK` or `MONTH`

**Response** `201 Created`:
```json
{
  "id": 1,
  "categoryId": 2,
  "categoryName": "Ăn uống",
  "amountLimit": 3000000.00,
  "spent": 850000.00,
  "available": 2150000.00,
  "period": "MONTH",
  "percentageUsed": 28
}
```

**Auto-calculated Fields**:
- `spent`: Sum of all EXPENSE transactions for this category in current period
- `available`: `amountLimit - spent`
- `percentageUsed`: `(spent / amountLimit) * 100`

**What Happens**:
1. ✅ System calculates current `spent` from existing transactions
2. ✅ Budget tracks spending in real-time
3. ✅ Every new EXPENSE transaction updates this budget automatically

---

### 5.2. Get Budget by ID

**Endpoint**: `GET /api/budgets/{id}`

**Response** `200 OK`: Single budget object with real-time calculations

---

### 5.3. Get All Budgets

Returns all budgets for the user with real-time spent/available data.

**Endpoint**: `GET /api/budgets`

**Headers**:
```http
User-Id: <UUID>
```

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "categoryId": 2,
    "categoryName": "Ăn uống",
    "amountLimit": 3000000.00,
    "spent": 850000.00,
    "available": 2150000.00,
    "period": "MONTH",
    "percentageUsed": 28
  },
  {
    "id": 2,
    "categoryId": 3,
    "categoryName": "Di chuyển",
    "amountLimit": 1500000.00,
    "spent": 1450000.00,
    "available": 50000.00,
    "period": "MONTH",
    "percentageUsed": 97
  }
]
```

**Use Case**: Display budget overview with progress bars showing spending status.

---

### 5.4. Update Budget

Updates budget limit or time period.

**Endpoint**: `PUT /api/budgets/{id}`

**Request Body**:
```json
{
  "categoryId": 2,
  "amountLimit": 3500000,
  "period": "MONTH"
}
```

**Response** `200 OK`: Updated budget with recalculated values

---

### 5.5. Delete Budget

Deletes a budget.

**Endpoint**: `DELETE /api/budgets/{id}`

**Response**: `204 No Content`

> ⚠️ **Note**: Related transactions remain intact. Only the budget tracking is removed.

---

## 6. Savings Goals API (ZBB Savings Fund)

Savings Goals are **long-term savings buckets** separate from wallets. They represent money you've committed to save for a specific purpose (e.g., "Buy iPhone", "Emergency Fund").

---

### 6.1. Create Savings Goal

**Endpoint**: `POST /api/savings-goals`

**Headers**:
```http
User-Id: <UUID>
Content-Type: application/json
```

**Request Body**:
```json
{
  "name": "Mua iPhone",
  "targetAmount": 20000000,
  "monthlyContribution": 2000000,
  "deadline": "2026-12-31",
  "icon": "phone"
}
```

**Field Descriptions**:
- `name`: Goal name
- `targetAmount`: Total amount needed
- `monthlyContribution`: Suggested monthly saving amount
- `deadline`: Target completion date
- `icon`: Icon identifier

**Response** `201 Created`:
```json
{
  "id": 1,
  "name": "Mua iPhone",
  "targetAmount": 20000000.00,
  "currentAmount": 0.00,
  "monthlyContribution": 2000000.00,
  "deadline": "2026-12-31",
  "icon": "phone",
  "percentageAchieved": 0
}
```

**Auto-calculated Fields**:
- `currentAmount`: Total savings committed to this goal
- `percentageAchieved`: `(currentAmount / targetAmount) * 100`

---

### 6.2. Contribute to Savings Goal

Adds money to a savings goal (usually via SAVINGS_COMMIT transaction).

**Endpoint**: `POST /api/savings-goals/{id}/contribute`

**Query Parameters**:
- `amount`: Amount to contribute

**Example**:
```http
POST /api/savings-goals/1/contribute?amount=500000
User-Id: <UUID>
```

**Response** `200 OK`:
```json
{
  "id": 1,
  "name": "Mua iPhone",
  "targetAmount": 20000000.00,
  "currentAmount": 500000.00,
  "monthlyContribution": 2000000.00,
  "deadline": "2026-12-31",
  "icon": "phone",
  "percentageAchieved": 2
}
```

**What Happens**:
1. ✅ `currentAmount` increases by contribution
2. ✅ `percentageAchieved` recalculated
3. 💡 This endpoint can be called directly or through SAVINGS_COMMIT transaction

---

### 6.3. Get Savings Goal by ID

**Endpoint**: `GET /api/savings-goals/{id}`

**Response** `200 OK`: Single savings goal object

---

### 6.4. Get All Savings Goals

Returns all savings goals with real-time progress.

**Endpoint**: `GET /api/savings-goals`

**Headers**:
```http
User-Id: <UUID>
```

**Response** `200 OK`: Array of savings goal objects

---

### 6.5. Update Savings Goal

**Endpoint**: `PUT /api/savings-goals/{id}`

**Request Body**: Same as Create Savings Goal

**Response** `200 OK`: Updated savings goal

---

### 6.6. Delete Savings Goal

**Endpoint**: `DELETE /api/savings-goals/{id}`

**Response**: `204 No Content`

> ⚠️ **Important**: Consider how to handle `currentAmount` when deleting. Options:
> - Transfer back to a wallet
> - Create reversal transaction
> - Require goal to be empty before deletion

---

## 7. User Settings API

### 7.1. Get Settings

Returns user application settings.

**Endpoint**: `GET /api/settings`

**Headers**:
```http
User-Id: <UUID>
```

**Response** `200 OK`:
```json
{
  "id": 1,
  "darkMode": false,
  "language": "VI",
  "defaultCurrency": "VND",
  "notificationEnabled": true,
  "budgetAlertThreshold": 80
}
```

**Field Descriptions**:
- `darkMode`: Dark mode enabled/disabled
- `language`: `VI` (Vietnamese) or `EN` (English)
- `defaultCurrency`: `VND` or `USD`
- `notificationEnabled`: Push notifications on/off
- `budgetAlertThreshold`: Percentage (0-100) to trigger budget warning (e.g., 80 = alert when 80% spent)

---

### 7.2. Update Settings

**Endpoint**: `PUT /api/settings`

**Headers**:
```http
User-Id: <UUID>
Content-Type: application/json
```

**Request Body**:
```json
{
  "darkMode": true,
  "language": "EN",
  "defaultCurrency": "USD",
  "notificationEnabled": true,
  "budgetAlertThreshold": 90
}
```

**Response** `200 OK`: Updated settings object

---

## 8. Dashboard API (ZBB Analytics)

Provides aggregated financial metrics for the user's dashboard.

### 8.1. Get Dashboard

**Endpoint**: `GET /api/dashboard`

**Headers**:
```http
User-Id: <UUID>
```

**Response** `200 OK`:
```json
{
  "netWorth": 15000000.00,
  "totalIncome": 5000000.00,
  "totalExpense": 3500000.00,
  "cashflowThisMonth": 1500000.00,
  "totalAssigned": 10000000.00,
  "totalAvailable": 6500000.00,
  "totalSavings": 2000000.00,
  "totalInvested": 5000000.00
}
```

### Metrics Explained

| Metric | Calculation | Purpose |
|--------|-------------|---------|
| `netWorth` | Sum of all wallet balances | Total liquid assets |
| `totalIncome` | Sum of INCOME transactions this month | Monthly earnings |
| `totalExpense` | Sum of EXPENSE transactions this month | Monthly spending |
| `cashflowThisMonth` | `totalIncome - totalExpense` | Net change this month |
| `totalAssigned` | Sum of all budget limits | Money given specific jobs (ZBB) |
| `totalAvailable` | Sum of all budgets' `available` | Unspent budget money |
| `totalSavings` | Sum of all savings goals' `currentAmount` | Money saved for goals |
| `totalInvested` | Sum of investment executions | Money in investments |

### Use Case
Display comprehensive financial overview on app home screen with:
- Net worth card
- Income vs Expense chart
- Budget allocation pie chart
- Savings progress bars

---

## Business Logic

### 1. Zero-Based Budgeting (ZBB) Flow

```
Step 1: Income arrives
  → INCOME transaction created
  → Wallet balance increases
  → totalIncome increases

Step 2: Assign every dollar
  → Create budgets for categories
  → totalAssigned = sum of budget limits
  → Ideal: totalIncome = totalAssigned

Step 3: Spend according to budget
  → EXPENSE transaction created
  → Wallet balance decreases
  → Budget's 'spent' increases
  → Budget's 'available' decreases

Step 4: Save for goals
  → SAVINGS_COMMIT transaction created
  → Wallet balance decreases
  → Savings goal progress increases
```

---

### 2. Transaction Balance Updates

| Transaction Type | Wallet From | Wallet To | Budget | Savings Goal |
|------------------|-------------|-----------|--------|--------------|
| INCOME | ➕ amount | - | - | - |
| EXPENSE | ➖ amount | - | ➖ available | - |
| TRANSFER | ➖ amount | ➕ amount | - | - |
| SAVINGS_COMMIT | ➖ amount | - | - | ➕ amount |
| INVESTMENT_EXECUTION | ➖ amount | - | - | - |

**Important**: All balance updates are **atomic**. If any part fails, the entire transaction is rolled back.

---

### 3. Budget Calculation Logic

```java
// Real-time calculation on each GET request
Budget budget = budgetRepository.findById(id);
BigDecimal spent = transactionRepository.sumExpensesByCategory(
    categoryId, 
    startOfPeriod, 
    endOfPeriod
);

budget.setSpent(spent);
budget.setAvailable(budget.getAmountLimit().subtract(spent));
budget.setPercentageUsed((spent / amountLimit) * 100);
```

**Period Boundaries**:
- `WEEK`: Last 7 days
- `MONTH`: Current calendar month

---

### 4. Data Integrity Rules

1. **Wallet Balance Cannot Go Negative**
   - EXPENSE and TRANSFER transactions validate balance before execution
   - Returns `400 Bad Request` if insufficient funds

2. **Category Type Matching**
   - INCOME transactions require INCOME category
   - EXPENSE transactions require EXPENSE category
   - TRANSFER does not require category

3. **Cascade Deletes**
   - Deleting a Wallet should handle related transactions (recommend soft delete)
   - Deleting a Category should block if budgets exist
   - Deleting a Budget does NOT delete transactions

4. **Audit Trail**
   - All transactions immutable after creation (recommend soft delete only)
   - Created/Updated timestamps on all entities

---

## Error Handling

### Error Response Format

All errors follow this structure:
```json
{
  "timestamp": "2026-02-02T23:15:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Insufficient balance in wallet"
}
```

### Common Error Codes

| Code | Error | Common Causes |
|------|-------|---------------|
| 400 | Bad Request | Invalid input, insufficient balance, business rule violation |
| 401 | Unauthorized | Invalid credentials, missing User-Id header |
| 404 | Not Found | Resource doesn't exist (Wallet, Category, Transaction, etc.) |
| 500 | Internal Server Error | Unexpected system error |

### Example Error Scenarios

**Insufficient Balance**:
```json
{
  "timestamp": "2026-02-02T23:15:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Insufficient balance in wallet 'Tiền Mặt'. Available: 100000, Required: 500000"
}
```

**Invalid Login**:
```json
{
  "timestamp": "2026-02-02T23:15:00",
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid email or password"
}
```

**Wallet Not Found**:
```json
{
  "timestamp": "2026-02-02T23:15:00",
  "status": 404,
  "error": "Resource Not Found",
  "message": "Wallet with id 999 not found"
}
```

---

## Common Use Cases

### Use Case 1: New User Setup

```
1. POST /api/auth/register
   → Get userId

2. POST /api/wallets (Create "Tiền Mặt" with 5,000,000)
   → Get walletId

3. GET /api/categories/system
   → Get default categories

4. POST /api/categories (Create custom "Ăn uống ngoài")
   → Get categoryId
```

---

### Use Case 2: Record Monthly Salary

```
1. POST /api/transactions
   {
     "walletId": 1,
     "categoryId": 1,  // "Lương"
     "type": "INCOME",
     "amount": 15000000,
     "note": "Lương tháng 2"
   }
   → Wallet balance: 5,000,000 → 20,000,000

2. GET /api/dashboard
   → totalIncome: 15,000,000
   → netWorth: 20,000,000
```

---

### Use Case 3: Create ZBB Budget Plan

```
After receiving 15,000,000 income, assign every dollar:

1. POST /api/budgets (Ăn uống: 3,000,000)
2. POST /api/budgets (Di chuyển: 1,500,000)
3. POST /api/budgets (Giải trí: 1,000,000)
4. POST /api/budgets (Học tập: 500,000)
5. POST /api/savings-goals (Quỹ khẩn cấp: 2,000,000 monthly)
6. POST /api/savings-goals (Mua laptop: 3,000,000 monthly)

Total Assigned: 11,000,000
Remaining: 4,000,000 (assign to more budgets or savings)
```

---

### Use Case 4: Daily Expense Tracking

```
1. POST /api/transactions (Lunch: 50,000)
   → Wallet: -50,000
   → Budget "Ăn uống" spent: +50,000
   → Budget "Ăn uống" available: -50,000

2. POST /api/transactions (Grab: 65,000)
   → Wallet: -65,000
   → Budget "Di chuyển" spent: +65,000

3. GET /api/budgets
   → See real-time spent/available for each budget
   → Check if approaching limits (percentageUsed)
```

---

### Use Case 5: Save for Goal

```
1. POST /api/savings-goals
   {
     "name": "Mua iPhone",
     "targetAmount": 20,000,000,
     "monthlyContribution": 2,000,000,
     "deadline": "2026-12-31"
   }
   → Get savingsGoalId

2. POST /api/transactions (SAVINGS_COMMIT)
   {
     "walletId": 1,
     "savingsGoalId": 1,
     "type": "SAVINGS_COMMIT",
     "amount": 2000000
   }
   → Wallet: -2,000,000
   → Goal progress: 0% → 10%

3. GET /api/savings-goals/1
   → currentAmount: 2,000,000
   → percentageAchieved: 10
```

---

### Use Case 6: Transfer Money Between Wallets

```
1. POST /api/transactions (TRANSFER from Bank to Cash)
   {
     "walletId": 2,      // Vietcombank
     "toWalletId": 1,    // Tiền Mặt
     "type": "TRANSFER",
     "amount": 1000000
   }
   → Vietcombank: -1,000,000
   → Tiền Mặt: +1,000,000
```

---

### Use Case 7: Monthly Financial Review

```
1. GET /api/dashboard
   → See overall metrics

2. GET /api/transactions/filter?startDate=2026-02-01&endDate=2026-02-28
   → Review all February transactions

3. GET /api/budgets
   → Check which budgets were overspent
   → Adjust next month's budget limits

4. GET /api/savings-goals
   → Check savings progress
   → Decide to increase/decrease contributions
```

---

## Best Practices for Frontend Integration

### 1. Balance Display
Always fetch latest wallet/budget data before transactions:
```javascript
// Before creating transaction
const wallet = await getWalletById(walletId);
if (wallet.balance < transactionAmount) {
  showError("Insufficient balance");
  return;
}
```

### 2. Real-time Budget Updates
After creating EXPENSE transaction, refresh budget list:
```javascript
await createTransaction(expenseData);
await getBudgets(); // Refresh to show updated spent/available
```

### 3. Date Handling
Always use ISO 8601 format for dates:
```javascript
const transactionDate = new Date().toISOString(); // "2026-02-02T23:15:00.000Z"
```

### 4. Error Handling
Display user-friendly messages:
```javascript
try {
  await createTransaction(data);
} catch (error) {
  if (error.status === 400) {
    showError(error.message); // "Insufficient balance..."
  } else {
    showError("Unexpected error occurred");
  }
}
```

### 5. Optimistic Updates
Update UI immediately, rollback on error:
```javascript
// Optimistically update wallet balance
setWalletBalance(prevBalance => prevBalance - amount);

try {
  await createExpenseTransaction(data);
} catch (error) {
  // Rollback on error
  setWalletBalance(prevBalance => prevBalance + amount);
  showError(error.message);
}
```

---

## Roadmap & Future Enhancements

- [ ] **JWT Authentication**: Replace User-Id header with Bearer tokens
- [ ] **Pagination**: Add pagination to list endpoints (transactions, budgets, etc.)
- [ ] **Soft Delete**: Implement soft delete for transactions to preserve history
- [ ] **Recurring Transactions**: Auto-create transactions on schedule (salary, rent, etc.)
- [ ] **Budget Templates**: Pre-defined budget templates for common scenarios
- [ ] **Export Data**: Export transactions to CSV/Excel
- [ ] **Analytics**: Advanced spending analytics and insights
- [ ] **Multi-currency**: Support multiple currencies with exchange rates
- [ ] **Shared Budgets**: Family/group budget sharing
- [ ] **Investment Tracking**: Full investment portfolio management

---

## Support & Contact

For API issues or questions:
- **Swagger UI**: http://localhost:8080/swagger-ui.html (interactive testing)
- **API Docs**: http://localhost:8080/api-docs (OpenAPI JSON)

---

**Last Updated**: 2026-02-02  
**API Version**: 1.0.0
