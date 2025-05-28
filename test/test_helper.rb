require 'minitest/autorun'
require 'webmock/minitest'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/nitpicker'

# Disable real HTTP connections during tests
WebMock.disable_net_connect!

# Common test utilities
module TestHelpers
  def setup_temp_config
    @temp_dir = Dir.mktmpdir
    @temp_config_dir = File.join(@temp_dir, '.config', 'nitpicker')
    FileUtils.mkdir_p(@temp_config_dir)
    
    # Stub CONFIG_DIR constant for testing
    NitPicker::CLI.const_set(:CONFIG_DIR, @temp_config_dir)
    NitPicker::CLI.const_set(:PROMPT_FILE, File.join(@temp_config_dir, 'prompt'))
    
    # Set testing mode
    Object.const_set(:TESTING_MODE, true)
  end

  def teardown_temp_config
    FileUtils.remove_entry(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    Object.send(:remove_const, :TESTING_MODE) if defined?(TESTING_MODE)
  end

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

  def mock_git_diff(diff_content)
    define_method :` do |command|
      return diff_content if command == "git diff --staged"
      super(command)
    end
  end

  def stub_openrouter_api(response_content, status: 200)
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .to_return(
        status: status,
        body: {
          choices: [
            {
              message: {
                content: response_content
              }
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end