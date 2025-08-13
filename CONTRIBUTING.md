# Contributing to ti.admob.unified

We welcome contributions to the ti.admob.unified project! This document provides guidelines for contributing to the project.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the issue template** when creating new issues
3. **Provide detailed information** including:
   - Titanium SDK version
   - Platform (iOS/Android) and version
   - Module version
   - Steps to reproduce the issue
   - Expected vs actual behavior
   - Code samples if applicable

### Suggesting Features

We're always interested in feature suggestions! Please:

1. **Check existing feature requests** to avoid duplicates
2. **Describe the use case** and why the feature would be valuable
3. **Provide examples** of how the feature would be used
4. **Consider backwards compatibility** implications

## 🔧 Development Setup

### Prerequisites

- **Titanium SDK**: 12.8.0 or higher
- **Xcode**: 14+ (for iOS development)
- **Android SDK**: API Level 21+ (for Android development)
- **Node.js**: Latest LTS version
- **Git**: Latest version

### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ti.admob.unified.git
   cd ti.admob.unified
   ```
3. **Create a new branch** for your feature/fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Building the Module

```bash
# Build for iOS
ti build -p ios --build-only

# Build for Android
ti build -p android --build-only

# Build for both platforms
ti build -p ios --build-only && ti build -p android --build-only
```

### Testing Your Changes

1. **Test with the example app**:
   ```bash
   cd example
   ti build -p [ios|android]
   ```

2. **Test on both platforms** (iOS and Android)

3. **Test different ad types** (banner, interstitial, rewarded, app open)

4. **Test consent flow** with different debug geographies

## 📝 Code Style Guidelines

### General Principles

- **Follow existing code style** and conventions
- **Write clean, readable code** with meaningful variable names
- **Add comments** for complex logic
- **Keep functions focused** and single-purpose
- **Use consistent formatting** throughout


### Objective-C (iOS)

- Use **4 spaces** for indentation
- Follow **Apple's Objective-C Style Guidelines**
- Use **explicit types** when clarity is improved
- Add **section comments** using `#pragma mark`
- Use **early returns** and **validation** for error prevention

Example:
```objc
//
// MxCodigomovilTiadmobunifiedModule.m
//

#pragma mark - Public Methods

- (RewardedAdProxy *)createRewarded:(NSDictionary *)config {
    if (![config isKindOfClass:[NSDictionary class]]) {
      config = @{};
    }
    return [[RewardedAdProxy alloc] initWithModule:self config:config];
}
```

### Java (Android)

- Use **4 spaces** for indentation
- Follow **Java coding conventions**
- Use **explicit types** for public APIs
- Add **Javadoc comments** for public methods
- Use **null checks** appropriately

Example:
```java
/**
 * Creates a rewarded ad proxy instance
 * @param config Configuration for the rewarded ad
 * @return RewardedAdProxy instance
 */
@Kroll.method
public RewardedAdProxy createRewarded(KrollDict config) {
  if (config == null) {
    config = new KrollDict();
  }
  return new RewardedAdProxy(this, config);
}
```

### JavaScript (Examples and Tests)

- Use **2 spaces** for indentation
- Use **const/let** instead of var
- Add **JSDoc comments** for functions
- Use **meaningful variable names**
- Follow **ES6+ conventions**

Example:
```javascript
/**
 * Creates and configures a rewarded ad
 * @param {string} adUnitId - The AdMob ad unit ID
 * @returns {Object} Configured rewarded ad instance
 */
function createRewardedAd(adUnitId) {
  const rewardedAd = Admob.createRewarded({
    autoReload: true,
    adUnitId: adUnitId,
  });

  return rewardedAd;
}
```

## 🧪 Testing Guidelines

### Required Tests

All contributions should include appropriate tests:

1. **Unit tests** for new functionality
2. **Integration tests** for API changes
3. **Platform-specific tests** for both iOS and Android
4. **Consent flow tests** for compliance features

### Test Categories

- **Basic functionality**: Ad loading, showing, and events
- **Error handling**: Network errors, invalid configurations
- **Consent management**: GDPR, CCPA, ATT flows
- **Platform differences**: Fresh ads, event mapping
- **Edge cases**: App lifecycle, memory management

### Testing Checklist

Before submitting a PR, ensure:

- [ ] Code builds successfully on both platforms
- [ ] Example app runs without errors
- [ ] All ad types work correctly
- [ ] Consent flow works in different geographies
- [ ] No memory leaks or crashes
- [ ] Performance is acceptable
- [ ] Documentation is updated

## 📚 Documentation Requirements

### Code Documentation

- **Add JSDoc/KDoc comments** for all public APIs
- **Document parameters** and return values
- **Include usage examples** in comments
- **Explain complex logic** with inline comments

### README Updates

When adding new features:

- **Update the API reference** section
- **Add new constants** to the constants section
- **Include usage examples**
- **Update the quick start** if applicable

### Changelog

- **Add entries** to CHANGELOG.md for all changes
- **Follow semantic versioning** principles
- **Include migration notes** for breaking changes

## 🔄 Pull Request Process

### Before Submitting

1. **Ensure your branch is up to date**:
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Run all tests** and ensure they pass

3. **Update documentation** as needed

4. **Add changelog entries** for your changes

### PR Description

Your pull request should include:

- **Clear description** of what the PR does
- **Related issue numbers** (if applicable)
- **Testing performed** and on which platforms
- **Breaking changes** (if any)
- **Screenshots** (for UI changes)

### PR Template

```markdown
## Description
Brief description of changes

## Related Issues
Fixes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on iOS
- [ ] Tested on Android
- [ ] Added/updated tests
- [ ] Updated documentation

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests pass
- [ ] Documentation updated
```

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **Code review** by maintainers
3. **Testing** on multiple devices/simulators
4. **Documentation review**
5. **Final approval** and merge

## 🚀 Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

### Release Workflow

1. **Update version numbers** in manifests
2. **Update CHANGELOG.md** with release notes
3. **Create release tag** and GitHub release
4. **Build and distribute** module packages
5. **Update documentation** if needed

## 🤔 Questions?

If you have questions about contributing:

- **Check existing issues** and discussions
- **Join the discussion** on GitHub Discussions
- **Contact maintainers** via email

## 📄 License

By contributing to ti.admob.unified, you agree that your contributions will be licensed under the [MIT License](LICENSE).

## 🙏 Recognition

All contributors will be recognized in the project README and release notes. Thank you for helping make ti.admob.unified better!
