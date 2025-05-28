require 'minitest/autorun'
require 'webmock/minitest'
require 'tmpdir'
require 'fileutils'
require 'stringio'
require_relative '../lib/nitpicker'

class NitPickerTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
    @temp_dir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
    
    # Create a mock git repository
    system('git init --quiet')
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')
    
    # Set up environment
    @original_api_key = ENV['OPENROUTER_API_KEY']
    @original_model = ENV['GIT_REVIEW_MODEL']
    ENV['OPENROUTER_API_KEY'] = 'test_key'
  end

  def teardown
    WebMock.reset!
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@temp_dir) if Dir.exist?(@temp_dir)
    
    # Restore environment
    if @original_api_key
      ENV['OPENROUTER_API_KEY'] = @original_api_key
    else
      ENV.delete('OPENROUTER_API_KEY')
    end
    
    if @original_model
      ENV['GIT_REVIEW_MODEL'] = @original_model
    else
      ENV.delete('GIT_REVIEW_MODEL')
    end
  end

  def test_version_is_defined
    refute_nil NitPicker::VERSION
    assert_instance_of String, NitPicker::VERSION
  end

  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+\z/, NitPicker::VERSION)
  end

  def test_cli_initialization
    cli = NitPicker::CLI.new
    assert_instance_of NitPicker::CLI, cli
  end

  def test_no_staged_changes_exits
    # No staged changes in empty repo
    cli = NitPicker::CLI.new
    
    assert_raises SystemExit do
      capture_io do
        cli.run
      end
    end
  end

  def test_missing_api_key_shows_helpful_message
    # Remove API key
    ENV.delete('OPENROUTER_API_KEY')
    
    # Create some staged changes
    File.write('test.rb', 'puts "hello"')
    system('git add test.rb')
    
    cli = NitPicker::CLI.new
    
    output, _error = capture_io do
      cli.run
    end
    
    assert_includes output, "OPENROUTER_API_KEY environment variable not set"
    assert_includes output, "https://openrouter.ai/"
    assert_includes output, "puts \"hello\""  # Should show the diff
  end

  def test_successful_api_call
    # Create a local prompt file
    File.write('.nitpicker_prompt', 'Review this: {{DIFF}}')
    
    # Create staged changes
    File.write('test.rb', 'puts "hello world"')
    system('git add test.rb')
    
    # Mock successful API response
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [
            {
              message: {
                content: "This code looks good. Simple and clear output."
              }
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    cli = NitPicker::CLI.new
    output, _error = capture_io do
      cli.run
    end
    
    assert_includes output, "This code looks good"
  end

  def test_custom_model_from_environment
    ENV['GIT_REVIEW_MODEL'] = 'openai/gpt-4o'
    
    File.write('.nitpicker_prompt', 'Review: {{DIFF}}')
    File.write('test.rb', 'def hello; end')
    system('git add test.rb')
    
    # Verify the custom model is used in the request
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .with(
        body: hash_including({
          model: 'openai/gpt-4o'
        })
      )
      .to_return(
        status: 200,
        body: {
          choices: [{ message: { content: "Good function definition." } }]
        }.to_json
      )
    
    cli = NitPicker::CLI.new
    capture_io { cli.run }
  end

  def test_api_error_handling
    File.write('.nitpicker_prompt', 'Review: {{DIFF}}')
    File.write('test.rb', 'bad code')
    system('git add test.rb')
    
    # Mock API error
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .to_return(status: 401, body: '{"error": {"message": "Unauthorized"}}')
    
    cli = NitPicker::CLI.new
    
    output, _error = capture_io do
      cli.run
    end
    
    assert_includes output, "API Error (401)"
    assert_includes output, "bad code"  # Should show the diff as fallback
  end

  def test_repository_prompt_takes_precedence
    # Create both global config and repo-specific prompt
    config_dir = File.expand_path('~/.config/nitpicker')
    FileUtils.mkdir_p(config_dir) unless Dir.exist?(config_dir)
    File.write(File.join(config_dir, 'prompt'), 'Global: {{DIFF}}')
    File.write('.nitpicker_prompt', 'Repo-specific: {{DIFF}}')
    
    File.write('test.rb', 'puts "test"')
    system('git add test.rb')
    
    # Verify repo-specific prompt is used
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .with { |request| 
        body = JSON.parse(request.body)
        body['messages'][0]['content'].include?('Repo-specific:')
      }
      .to_return(
        status: 200,
        body: { choices: [{ message: { content: "Review complete" } }] }.to_json
      )
    
    cli = NitPicker::CLI.new
    capture_io { cli.run }
  end

  private

  def capture_io
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = stdout = StringIO.new
    $stderr = stderr = StringIO.new
    yield
    [stdout.string, stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end