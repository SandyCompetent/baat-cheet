# Contributing to ChatBud

First off, thank you for considering contributing to ChatBud! It's people like you that make ChatBud a great project.

## Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](.github/CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:
* Use a clear and descriptive title.
* Describe the exact steps which reproduce the problem in as many details as possible.
* Provide specific examples to demonstrate the steps.

### Suggesting Enhancements

If you have a feature request or an enhancement idea:
* Check if there's already a similar request in the issues.
* Use a clear and descriptive title.
* Provide a step-by-step description of the suggested enhancement.
* Explain why this enhancement would be useful.

### Pull Requests

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes (`flutter test`).
5. Ensure your code is properly formatted (`dart format .`).
6. Make sure there are no linting errors (`flutter analyze`).
7. Create the PR with a descriptive title and detailed description of the changes.

## Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR_GITHUB_USERNAME/chatbud.git
   cd chatbud
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   # Run on Chrome Web
   flutter run -d chrome

   # Run on Android or iOS
   flutter run
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

Thank you for contributing!
