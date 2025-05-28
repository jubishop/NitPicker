# NitPicker Usage Examples

## Quick Start

1. **Set your API key**:
   ```bash
   export OPENROUTER_API_KEY="your_openrouter_api_key_here"
   ```

2. **Navigate to your Git repository**:
   ```bash
   cd your-project
   ```

3. **Review staged changes** (default):
   ```bash
   git add .
   # or stage specific files
   git add src/main.rb
   
   # Run NitPicker
   nitpicker
   ```

4. **Or review any diff via pipe**:
   ```bash
   # Review a specific commit
   git show | nitpicker
   
   # Review changes from previous commit
   git diff HEAD~1 | nitpicker
   ```

## Basic Examples

### Example 1: Simple Code Review (Staged Changes)

```bash
# Make some changes to your code
echo 'def hello_world; puts "Hello, World!"; end' > hello.rb

# Stage the changes
git add hello.rb

# Get AI review
nitpicker
```

**Example Output**:
```
## Code Review Summary

**Overall Assessment:** The code is simple and functional, but could benefit from some improvements.

### Positive Aspects:
- Clear, descriptive method name
- Simple implementation that works as intended

### Suggestions for Improvement:

**Best Practices:**
- Consider adding documentation for the method to explain its purpose
- The method could return the string instead of just printing it for better testability

**Suggested Implementation:**
```ruby
# Prints a friendly greeting to the console
def hello_world
  message = "Hello, World!"
  puts message
  message
end
```

This would make the method more testable and follow Ruby conventions better.
```

### Example 2: Review via Piped Diff

```bash
# Review the last commit you made
git show | nitpicker

# Review changes between two commits
git diff HEAD~2..HEAD | nitpicker

# Review uncommitted changes (staged and unstaged)
git diff HEAD | nitpicker

# Review differences between branches
git diff main..feature-branch | nitpicker
```

**Example Output**:
```
## Code Review Summary

**Overall Assessment:** These changes introduce a new feature with good structure, but there are some areas for improvement.

### Positive Aspects:
- Well-organized code structure
- Good separation of concerns
- Comprehensive test coverage

### Suggestions for Improvement:

**Performance:**
- Consider caching the database query result on line 45 to avoid repeated calls
- The loop on line 67 could be optimized using a more efficient algorithm

**Security:**
- Input validation should be added for user-provided parameters
- Consider using parameterized queries to prevent SQL injection

This review covers 156 lines of changes across 4 files.
```

### Example 3: Using Custom Model

```bash
# Set a different AI model
export GIT_REVIEW_MODEL="openai/gpt-4o"

# Stage your changes and review
git add .
nitpicker

# Or pipe any diff with custom model
git show HEAD~1 | nitpicker
```

### Example 4: Repository-Specific Prompt

```bash
# Create a custom prompt for this repository
cat > .nitpicker_prompt << EOF
You are reviewing Ruby code for a web application. Focus specifically on:

1. Ruby idioms and best practices
2. Rails conventions (if applicable)
3. Security vulnerabilities specific to web applications
4. Performance implications for web requests
5. Database query efficiency

Provide specific, actionable feedback with code examples.

DIFF:
{{DIFF}}
EOF

# Now use the custom prompt
git add some_file.rb
nitpicker
```

## Configuration Examples

### Global Configuration

```bash
# Set up global prompt
mkdir -p ~/.config/nitpicker
cat > ~/.config/nitpicker/prompt << EOF
You are an expert software engineer conducting a thorough code review.

Focus on:
- Code quality and maintainability
- Security vulnerabilities
- Performance optimizations
- Testing coverage
- Documentation

Be constructive and specific in your feedback.

DIFF:
{{DIFF}}
EOF
```

### Environment Variables

```bash
# Required: OpenRouter API key
export OPENROUTER_API_KEY="sk-or-v1-..."

# Optional: Custom model (default: openai/gpt-4.1-mini)
export GIT_REVIEW_MODEL="anthropic/claude-3-haiku"

# Optional: Alternative models
export GIT_REVIEW_MODEL="openai/gpt-4o-mini"
export GIT_REVIEW_MODEL="meta-llama/llama-3.1-8b-instruct"
```

## Integration Examples

### Pre-commit Hook

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Run NitPicker as part of pre-commit process

if command -v nitpicker &> /dev/null; then
    echo "Running AI code review..."
    if git diff --staged --quiet; then
        echo "No staged changes to review."
    else
        nitpicker
        echo "Review complete. Proceeding with commit..."
    fi
fi
```

### Post-commit Hook

Create `.git/hooks/post-commit`:
```bash
#!/bin/bash
# Review the commit that was just made

if command -v nitpicker &> /dev/null; then
    echo "Reviewing the commit you just made..."
    git show | nitpicker
fi
```

### CI/CD Integration

```yaml
# GitHub Actions example
name: Code Review
on: [pull_request]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0
      - name: Install NitPicker
        run: gem install nitpicker-code-review
      - name: Run AI Review
        env:
          OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
        run: |
          git fetch origin main
          # Review changes in the PR
          git diff origin/main..HEAD | nitpicker || true  # Don't fail CI on review feedback
```

## Advanced Usage

### Multiple File Review

**Using staged changes:**
```bash
# Review specific types of files
git add *.rb
nitpicker

# Review everything
git add .
nitpicker
```

**Using piped diffs:**
```bash
# Review only Ruby files in the last commit
git show --name-only --pretty=format: HEAD | grep '\.rb$' | xargs git show HEAD -- | nitpicker

# Review specific file changes
git diff HEAD~1 -- app/models/ | nitpicker
```

### Large Changesets

For large changesets, consider reviewing in smaller chunks:

**Using staged changes:**
```bash
# Review database migrations separately
git add db/migrate/*
nitpicker

# Then review application code
git reset
git add app/
nitpicker

# Finally review tests
git reset
git add spec/ test/
nitpicker
```

**Using piped diffs:**
```bash
# Review database migrations from a commit
git show HEAD -- db/migrate/ | nitpicker

# Review application code changes
git show HEAD -- app/ | nitpicker

# Review test changes
git show HEAD -- spec/ test/ | nitpicker
```

### Custom Prompts for Different File Types

Create specialized prompts:

```bash
# For JavaScript/TypeScript projects
cat > .nitpicker_prompt << EOF
You are reviewing JavaScript/TypeScript code. Focus on:
- Modern ES6+ syntax and best practices
- Type safety (for TypeScript)
- Async/await patterns
- Error handling
- Security (XSS, injection attacks)
- Performance and bundle size impact

DIFF:
{{DIFF}}
EOF

# For Python projects
cat > .nitpicker_prompt << EOF
You are reviewing Python code. Focus on:
- PEP 8 style compliance
- Pythonic idioms
- Type hints
- Security vulnerabilities
- Performance optimizations
- Test coverage

DIFF:
{{DIFF}}
EOF
```

## Troubleshooting

### No Staged Changes or Piped Input
```bash
$ nitpicker
No changes staged for review.
```
**Solution**: Stage some changes first with `git add` or pipe a diff into nitpicker

```bash
$ echo "" | nitpicker
No diff content provided via pipe.
```
**Solution**: Provide a valid diff via pipe: `git show | nitpicker`

### Missing API Key
```bash
$ nitpicker
Error: OPENROUTER_API_KEY environment variable not set
```
**Solution**: Set your API key: `export OPENROUTER_API_KEY="your_key"`

### API Errors
```bash
$ nitpicker
API Error (401): {"error": "Unauthorized"}
```
**Solution**: Check your API key is valid and has sufficient credits

## Tips for Better Reviews

1. **Stage related changes together**: Group logically related changes for more coherent reviews
2. **Use descriptive commit messages**: While NitPicker reviews code, good commit messages help provide context
3. **Create project-specific prompts**: Tailor the review criteria to your project's needs
4. **Review incrementally**: For large features, review smaller chunks as you develop
5. **Combine with human review**: AI reviews complement but don't replace human code review