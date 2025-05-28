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

3. **Stage some changes**:
   ```bash
   git add .
   # or stage specific files
   git add src/main.rb
   ```

4. **Run NitPicker**:
   ```bash
   nitpicker
   ```

## Basic Examples

### Example 1: Simple Code Review

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

### Example 2: Using Custom Model

```bash
# Set a different AI model
export GIT_REVIEW_MODEL="openai/gpt-4o"

# Stage your changes and review
git add .
nitpicker
```

### Example 3: Repository-Specific Prompt

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
          git diff origin/main..HEAD > changes.diff
          if [ -s changes.diff ]; then
            # Create a temporary commit to review
            git add -A
            nitpicker || true  # Don't fail CI on review feedback
          fi
```

## Advanced Usage

### Multiple File Review

```bash
# Review specific types of files
git add *.rb
nitpicker

# Review everything
git add .
nitpicker
```

### Large Changesets

For large changesets, consider reviewing in smaller chunks:

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

### No Staged Changes
```bash
$ nitpicker
No changes staged for review.
```
**Solution**: Stage some changes first with `git add`

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