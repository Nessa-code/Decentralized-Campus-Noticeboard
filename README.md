# Campus Noticeboard Smart Contract

A decentralized noticeboard system for campus announcements with immutable history tracking.

## Features

- Post notices with title, content, and category
- Immutable notice history
- User posting statistics
- Notice deactivation by original author

## Contract Functions

### Public Functions

- `post-notice` - Create a new notice on the board
- `deactivate-notice` - Deactivate your own notice

### Read-Only Functions

- `get-notice` - Retrieve a specific notice by ID
- `get-user-notice-count` - Get total notices posted by a user
- `get-notice-nonce` - Get current notice counter

## Usage

Deploy with Clarinet and interact through the Stacks blockchain.