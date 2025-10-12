# Contributing to this repository
Welcome, and thank you for your interest in contributing!  
This document outlines how to get started, our development standards, and how we keep the project consistent, readable and maintainable.

---
## Table of Contents
1. [Overview](#overview)  
2. [Community](#community)  
3. [Getting Started](#getting-started)  
4. [Code Style and Formatting](#code-style-and-formatting)  
5. [Commit Messages](#commit-messages)  
6. [Pull Requests](#pull-requests)  
7. [Code of Conduct](#code-of-conduct)

---
## Overview
We welcome all forms of contribution — bug reports, tests, code or feedback, given that you use the proper channels to give them.
Every contribution helps improve the project for everyone.  

This guide will help you follow our coding conventions, and submit high-quality pull requests that can be merged smoothly

---
## Community
We encourage open communication and collaboration.
You can reach out through the following channels:
- **GitHub Issues** or **Discord Community Tickets** — for reporting bugs and feature requests.
- **GitHub Discussions** or **The Discord Community General Channel** — for questions, design proposals, or brainstorming.
- **Pull Requests** — for direct contributions.  

Please be respectful and constructive in all of your interactions.

---
## Getting Started
1. **Install the GitHub cli and log into GitHub**
`sudo apk add github-cli && gh auth login -w -c`

2. **Install the Lua formatter**
`cargo install stylua` or `brew install stylua` on Mac

3. **Fork and clone the repository**
```bash
gh repo fork --clone https://github.com/the-unnamed-goose/lua-buffoonery
cd lua-buffoonery
```

3. **Create a new branch and make a pull request on GitHub**
```bash
git checkout -b feature/some-new-feature #Look at https://medium.com/@abhay.pixolo/naming-conventions-for-git-branches-a-cheatsheet-8549feca2534 for details
git add .
git commit -m "The new feature's description"
git push
gh pr create --base development --head yourusername:feature/some-new-feature --title "Add feature XYZ" --body "This PR adds XYZ functionality by doing N."
```

---
## Code Style and Formatting
1. General formatting
We follow the default StyLua conventions:
Indentation: 4 spaces
Quotes: double quotes
Trailing commas: none
Tables: compact formatting when possible
Line width: 120 characters
End of file: newline required

You may include this configuration file at the root of the repository if you also maintain other repositories:
```toml
# stylua.toml
column_width = 120
indent_width = 4
quote_style = "double"
no_call_parentheses = false
```

2. Naming Conventions
Consistent naming is critical for clarity and maintainability. Please follow these rules for all identifiers:
* - no underscores or dashes
Game services - start with uppercase and have a one word cap
All literal types - sneak case
Values that are mutable at runtime and functions - camel case

3. File Structure and Definitions
All definitions — service references, constants and variable initializations must appear at the top of every Lua file, preferably in this order.

Example:
```lua
local Service = game:GetService("UserInputService")
local LITERAL = "arbitrary value"
local mutableValue = nil -- or the initial value
```

---
## Commit Messages
We follow conventional commit style:
Type	Description	Example

feat	New feature	feat: add player damage scaling to custom weapon controller
fix	Bug fix	fix: correct estimations of protein folding
docs	Documentation update	docs: add usage section to README
refactor	Code change that improves structure	refactor: simplify hooking logic

---
## Pull Requests
- Keep PRs focused and small.
- Link to issues if applicable (Fixes #42).
- Ensure all code passes stylua formatting, we would want any syntax errors to slip into upstream.
- Test the modified scripts for bugs and regressions or get someone to test them for you before submitting a PR.

---
## Code of Conduct
By contributing, you agree to uphold our Code of Conduct:
- Be respectful and considerate.
- Welcome newcomers and different perspectives.
- Assume positive intent.
- Focus on constructive technical feedback, not personal criticism.

---
Thank You!

Every contribution, no matter the size, helps this project grow. We appreciate your effort, your ideas, and your collaboration.