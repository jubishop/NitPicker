# NitPicker

NitPicker is a command-line tool that provides AI-powered code reviews for your Git changes. It analyzes your staged changes and offers constructive feedback to help improve code quality, security, performance, and maintainability.

## Features

- AI-powered code review of staged Git changes
- Comprehensive analysis covering code quality, security, performance, and best practices
- Customizable AI prompts for tailored review feedback
- Support for repository-specific prompts
- Choose any AI model (OpenAI GPT-4.1-mini by default)
- Easy integration into your Git workflow

## Installation

### Requirements

- Ruby 2.6 or higher
- Git

### Option 1: Install as a Gem (Recommended)

```bash
gem install nitpicker-code-review
```

This automatically adds NitPicker to your PATH.

### Option 2: Build and Install from Source

Clone this repository:

```bash
git clone https://github.com/jubishop/NitPicker.git
cd NitPicker
```

Build and install the gem:

```bash
gem build gemspec/nitpicker.gemspec
gem install nitpicker-code-review-*.gem
```

### Option 3: Manual Installation

Clone this repository:

```bash
git clone https://github.com/jubishop/NitPicker.git
cd NitPicker
```

Make the script executable:

```bash
chmod +x bin/nitpicker
```

Create a symbolic link to make NitPicker available globally:

```bash
ln -s "$(pwd)/bin/nitpicker" /usr/local/bin/nitpicker
```

## Configuration

### API Key Setup

NitPicker requires an OpenRouter API key to generate code reviews. You need to set this as an environment variable:

```bash
export OPENROUTER_API_KEY="your_openrouter_api_key"
```

You can get an API key from [OpenRouter](https://openrouter.ai/).

Optionally, you can specify a different model by setting:

```bash
export GIT_REVIEW_MODEL="openai/gpt-4o"
```

The default model is `openai/gpt-4.1-mini` if not specified.

### Prompt Configuration

NitPicker supports two levels of prompt configuration:

- **Global Prompt (Default)**: Stored in `~/.config/nitpicker/prompt`. This is used for all repositories unless overridden.
- **Repository-Specific Prompt**: Create a `.nitpicker_prompt` file in the root of your Git repository to customize the prompt for that specific project.

When you run NitPicker, it will:
- First look for a `.nitpicker_prompt` file in the root of the current Git repository
- If not found, fall back to the global prompt at `~/.config/nitpicker/prompt`

When you run NitPicker for the first time, if there's no global prompt file in the config directory, it will copy `config/prompt` to the config directory automatically.

The special string `{{DIFF}}` in your prompt will be replaced with the current git diff of staged changes.

## Usage

Navigate to your Git repository, stage your changes, and run:

```bash
nitpicker [options]
```

Options:
- `--version`: Show version information
- `-h, --help`: Show help message

## Examples

```bash
# Stage some changes first
git add .

# Get AI code review of staged changes
nitpicker
```

Example output:
```
## Code Review Summary

**Overall Assessment:** The changes look good with a few minor suggestions for improvement.

### Positive Aspects:
- Clean, readable code structure
- Proper error handling implemented
- Good variable naming conventions

### Suggestions for Improvement:

**Security:**
- Consider validating user input on line 45 to prevent potential injection attacks

**Performance:**
- The database query on line 23 could be optimized by adding an index on the `user_id` column

**Best Practices:**
- Consider extracting the validation logic into a separate method for better reusability
```

## License

MIT

## Development

### Project Structure

NitPicker follows a specific project structure where all gemspec files and built gem files (.gem) are placed in the `gemspec/` folder rather than the root directory. This keeps the root directory clean and organized.

### Rake Tasks

NitPicker provides several rake tasks to streamline development:

```bash
# Run the test suite
rake test

# Build the gem and place it in the gemspec/ folder
rake build

# Build, install and test the gem
rake install

# Build and push the gem to RubyGems
rake push
```

The default task is `rake test`.

### Testing

NitPicker uses Minitest for testing. To run the tests:

```bash
bundle install
rake test
```

The test suite includes:
- Unit tests for the CLI functionality
- Tests for version consistency
- Mock tests for API interactions (using WebMock)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Author

Justin Bishop (jubishop)