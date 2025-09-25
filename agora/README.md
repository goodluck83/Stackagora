# Stackagora 

> A decentralized social network built on Stacks, where users truly own their content and govern their community.

Stackagora combines the ancient Greek concept of the agora (a public assembly space) with modern blockchain technology to create a censorship-resistant social platform secured by Bitcoin.

##  Features

### Core Social Features
- **User Registration & Profiles**: Create your identity with username and bio
- **Post Creation**: Share thoughts, ideas, and content (up to 500 characters)
- **Voting System**: Upvote and downvote posts to surface quality content
- **Following System**: Follow users you're interested in
- **Reputation System**: Build reputation through quality content and community engagement

### Economic Features
- **Tipping System**: Tip creators directly with STX tokens
- **Creator Monetization**: Authors receive tips minus a small platform fee
- **Reputation-Based Rewards**: Earn reputation points for upvotes and tips received

### Governance & Moderation
- **Content Ownership**: All posts are stored on-chain and owned by creators
- **Community Governance**: Vote on posts to determine what content is valued
- **Transparent Moderation**: Moderation actions are recorded on-chain

##  Architecture

### Smart Contract Functions

#### User Management
- `register-user`: Create a new user profile
- `get-user`: Retrieve user information
- `follow-user` / `unfollow-user`: Manage following relationships

#### Content Creation & Interaction
- `create-post`: Publish new content
- `vote-post`: Upvote or downvote posts
- `tip-post`: Send STX tips to content creators
- `get-post`: Retrieve post data

#### Platform Features
- `get-platform-stats`: View network statistics
- `get-user-reputation`: Check user reputation scores
- `moderate-post`: Platform moderation (owner only)

### Data Structure

**Users**:
```clarity
{
  user-id: uint,
  username: string,
  bio: string,
  posts-count: uint,
  reputation: uint,
  total-tips-received: uint,
  joined-at: uint
}
```

**Posts**:
```clarity
{
  author: principal,
  content: string,
  timestamp: uint,
  upvotes: uint,
  downvotes: uint,
  tips-received: uint,
  is-active: bool
}
```

##  Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) for frontend development
- Stacks wallet (Hiro Wallet recommended)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/goodluck83/Stackagora.git
cd stackagora
```

2. Initialize Clarinet project:
```bash
clarinet new stackagora
cd stackagora
```

3. Add the contract:
```bash
# Copy the stackagora.clar file to contracts/
cp ../stackagora.clar contracts/
```

4. Test the contract:
```bash
clarinet test
```

5. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Test contract functions:
```clarity
;; Register a user
(contract-call? .stackagora register-user "alice" "Blockchain enthusiast")

;; Create a post
(contract-call? .stackagora create-post "Hello Stackagora! Excited to be here.")

;; Vote on a post
(contract-call? .stackagora vote-post u1 "upvote")
```

##  Economics

### Tipping System
- Minimum tip: 1 STX
- Platform fee: 2.5% (adjustable by contract owner)
- Tips go directly to content creators
- Tipping increases both post visibility and author reputation

### Reputation System
- New users start with 100 reputation points
- Upvotes: +5 reputation for author
- Downvotes: -5 reputation for author (minimum 0)
- Receiving tips: +10 reputation bonus

##  Security Features

- **Bitcoin-Secured**: All transactions are finalized on Bitcoin through Stacks
- **Censorship Resistance**: Content stored on-chain cannot be easily removed
- **Economic Security**: Spam prevention through tipping minimums
- **Transparent Governance**: All moderation actions are on-chain

##  Roadmap

### Phase 1: Core Platform (Current)
-  User registration and profiles
-  Post creation and voting
-  Tipping system
-  Basic moderation

### Phase 2: Enhanced Social Features
- [ ] Comments on posts
- [ ] Private messaging
- [ ] User mentions and notifications
- [ ] Rich media support

### Phase 3: Advanced Governance
- [ ] Community-driven moderation
- [ ] Governance token distribution
- [ ] Decentralized platform decisions
- [ ] Content categories and filtering

### Phase 4: Ecosystem Integration
- [ ] NFT profile pictures
- [ ] Integration with other Stacks DeFi protocols
- [ ] Mobile applications
- [ ] API for third-party clients