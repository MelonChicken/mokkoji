# GitHub Actions CI/CD Workflows

This directory contains GitHub Actions workflows for automated testing, building, and quality checks.

## 📋 Workflows

### 1. Flutter CI (`flutter-ci.yml`)

Main CI pipeline that runs on every push and pull request.

**Jobs:**
- **Analyze**: Code formatting, static analysis, forbidden filenames check
- **Test**: Unit tests with coverage reporting
- **Build Android**: APK build for arm64-v8a, armeabi-v7a, x86_64
- **Build iOS**: iOS build (macOS runner, main branch only)

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main` or `develop`
- Manual dispatch

**Artifacts:**
- Android APK files (7 days retention)
- iOS IPA file (7 days retention, main only)

### 2. PR Validation (`pr-validation.yml`)

Automated PR quality checks with bot comments.

**Jobs:**
- **PR Checks**:
  - PR title format (conventional commits)
  - PR description presence
  - Merge conflict detection
  - Commit message validation
  - Large file detection
  - Dependency vulnerability check
  - Automated PR comment with results

- **Size Check**:
  - Bundle size analysis
  - APK size reporting
  - Size optimization warnings

**Triggers:**
- Pull request opened, synchronized, reopened

**Features:**
- ✅ Conventional commits validation
- 📦 Bundle size tracking
- 🤖 Automated PR comments
- ⚠️ Large file warnings

### 3. Code Quality (`code-quality.yml`)

Weekly code quality checks and security scans.

**Jobs:**
- **Forbidden Filenames**: Enforce naming conventions
- **Dependencies Audit**: Check outdated packages and duplicates
- **Code Metrics**: LOC counting, test ratio, file size analysis
- **Security Scan**:
  - Hardcoded secrets detection
  - Debug statement detection
  - TODO/FIXME tracking

**Triggers:**
- Push to `main` or `develop`
- Pull requests to `main` or `develop`
- Weekly schedule (Monday 00:00 UTC)

**Artifacts:**
- Code metrics report (30 days retention)

## 🚀 Usage

### Running Workflows Locally

Test workflow syntax:
```bash
# Install act (https://github.com/nektos/act)
brew install act  # macOS
# or
choco install act-cli  # Windows

# Run workflow locally
act -j analyze  # Run analyze job
act pull_request  # Simulate PR event
```

### Manual Workflow Dispatch

Trigger workflows manually from GitHub Actions tab:
1. Go to Actions tab
2. Select workflow
3. Click "Run workflow"
4. Choose branch and run

### Required Secrets

Configure in repository settings (Settings → Secrets and variables → Actions):

| Secret | Required | Description |
|--------|----------|-------------|
| `CODECOV_TOKEN` | Optional | Codecov upload token for coverage reports |

## 📊 Status Badges

Add to your README.md:

```markdown
[![Flutter CI](https://github.com/MelonChicken/mokkoji/workflows/Flutter%20CI/badge.svg)](https://github.com/MelonChicken/mokkoji/actions?query=workflow%3A%22Flutter+CI%22)
[![PR Validation](https://github.com/MelonChicken/mokkoji/workflows/PR%20Validation/badge.svg)](https://github.com/MelonChicken/mokkoji/actions?query=workflow%3A%22PR+Validation%22)
[![Code Quality](https://github.com/MelonChicken/mokkoji/workflows/Code%20Quality/badge.svg)](https://github.com/MelonChicken/mokkoji/actions?query=workflow%3A%22Code+Quality%22)
```

## 🔧 Customization

### Modify Flutter Version

Update `flutter-version` in all workflows:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.29.0'  # Change this
    channel: 'stable'
```

### Add New Jobs

Add to existing workflows or create new ones:
```yaml
jobs:
  my-new-job:
    name: My Custom Job
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run custom script
        run: ./my-script.sh
```

### Cache Optimization

Current caching:
- Flutter SDK (via `subosito/flutter-action`)
- Gradle dependencies (Java setup)
- Pub dependencies (automatic)

## 📝 Best Practices

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add new feature
fix: resolve bug
docs: update documentation
style: format code
refactor: restructure code
perf: improve performance
test: add tests
build: update build config
ci: modify CI/CD
chore: routine tasks
```

### PR Titles

Must follow conventional commits format:
- ✅ `feat: add AI voice commands`
- ✅ `fix(ui): resolve button alignment`
- ❌ `Updated files`
- ❌ `bug fix`

### File Naming

Avoid versioned filenames:
- ❌ `file_v2.dart`, `code_old.dart`, `backup_final.dart`
- ✅ Use git history instead
- ✅ Detected by `check_forbidden_filenames.sh`

## 🐛 Troubleshooting

### Workflow Fails on Dependencies

```bash
# Clear pub cache
flutter pub cache repair

# Update dependencies
flutter pub upgrade
```

### Build Runner Errors

```bash
# Clean and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### iOS Build Fails

- iOS builds only run on `main` branch (macOS runners are expensive)
- No codesigning configured (use local Xcode for signed builds)

### Permission Denied on Scripts

```bash
# Make scripts executable
chmod +x tools/ci/check_forbidden_filenames.sh
```

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Conventional Commits](https://www.conventionalcommits.org/)
