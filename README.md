# 📚 BookChain - On-Chain E-Book Library

> A decentralized library for digital books where access is managed by smart contracts, ensuring fair royalties for authors 📖✨

## 🎯 Overview

BookChain is a revolutionary decentralized e-book platform built on the Stacks blockchain. Authors can publish their books, set prices for purchases and rentals, while readers can access a vast library of digital content with guaranteed ownership and fair author compensation.

## ✨ Features

### 📝 For Authors
- **Publish Books**: Add your e-books to the decentralized library
- **Set Pricing**: Define purchase and rental prices independently  
- **Earn Royalties**: Receive payments directly for every sale/rental
- **Manage Availability**: Control when your books are available
- **Track Earnings**: Monitor your total earnings on-chain

### 📖 For Readers
- **Purchase Books**: Buy permanent access to e-books
- **Rent Books**: Temporary access (1-30 days) at lower cost
- **Personal Library**: Track owned and rented books
- **Verified Access**: Blockchain-verified reading permissions
- **Fair Pricing**: Transparent pricing with low platform fees

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet (for testnet/mainnet deployment)

### Installation

```bash
git clone https://github.com/your-username/On-Chain-E-Book-Library
cd On-Chain-E-Book-Library
clarinet check
```

## 📋 Contract Functions

### 🔧 Public Functions

#### `add-book`
Add a new book to the library (Contract owner only)
```clarity
(contract-call? .BookChain add-book "Book Title" u1000000 u50000 u100)
```

#### `purchase-book` 
Purchase permanent access to a book
```clarity
(contract-call? .BookChain purchase-book u1)
```

#### `rent-book`
Rent a book for specified days (1-30 days)
```clarity
(contract-call? .BookChain rent-book u1 u7)
```

#### `update-book-status`
Enable/disable book availability (Author only)
```clarity
(contract-call? .BookChain update-book-status u1 true)
```

### 👀 Read-Only Functions

#### `get-book`
Get book details by ID
```clarity
(contract-call? .BookChain get-book u1)
```

#### `has-access`
Check if user has access to a book
```clarity
(contract-call? .BookChain has-access u1 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### `get-rental-status`
Check rental expiration for a user
```clarity
(contract-call? .BookChain get-rental-status u1 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### `get-user-library`
Get user's owned and rented books
```clarity
(contract-call? .BookChain get-user-library 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

## 💰 Economics

- **Platform Fee**: 5% (adjustable by contract owner)
- **Author Royalty**: 95% of each sale/rental
- **STX Payments**: All transactions in STX tokens
- **Rental Duration**: 1-30 days maximum

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 📁 Project Structure

```
├── contracts/
│   └── BookChain.clar          # Main smart contract
├── tests/
│   └── BookChain_test.ts       # Contract tests
├── settings/
│   └── Devnet.toml            # Development settings
├── Clarinet.toml              # Project configuration
└── README.md                  # This file
```

## 🔒 Security Features

- **Access Control**: Only authorized users can modify books
- **Payment Verification**: STX transfers are atomic
- **Time-based Rentals**: Block-height based expiration
- **Ownership Tracking**: Immutable purchase records

## 🛠️ Development

### Local Development
```bash
clarinet console
```

### Deploy to Testnet
```bash
clarinet deploy --testnet
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Clarinet](https://github.com/hirosystems/clarinet)
- Powered by [Stacks Blockchain](https://www.stacks.co/)
- Inspired by the vision of decentralized publishing

---

**Happy Reading! 📚🚀**
