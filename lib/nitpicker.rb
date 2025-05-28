require 'nitpicker/version'
require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'tmpdir'

module NitPicker
  class CLI
    CONFIG_DIR = File.expand_path('~/.config/nitpicker')
    PROMPT_FILE = File.join(CONFIG_DIR, 'prompt')
    REPO_PROMPT_FILE = '.nitpicker_prompt'

    def initialize
      @options = {}
      setup_config_dir
    end

    def parse_options
      require 'optparse'
      
      OptionParser.new do |opts|
        opts.banner = 'Usage: nitpicker [options]
       git show | nitpicker              # Review a specific commit
       git diff HEAD~1 | nitpicker       # Review changes from previous commit
       nitpicker                         # Review staged changes (default)'
        opts.version = VERSION

        opts.on('-h', '--help', 'Show this help message') do
          puts opts
          exit
        end
      end.parse!
    end

    def run
      parse_options
      
      # Check if we have piped input
      if STDIN.tty?
        # Interactive terminal - use git diff of staged changes
        diff = `git diff --staged`
        if diff.empty?
          puts "No changes staged for review."
          exit 1
        end
      else
        # STDIN is redirected - try to read from it
        diff = STDIN.read
        if diff.empty?
          # Empty piped input, fall back to git diff
          diff = `git diff --staged`
          if diff.empty?
            puts "No changes staged for review."
            exit 1
          end
        end
      end

      # Get AI-generated code review
      review = generate_code_review(diff)
      
      # Display the review
      puts review
    end

    private

    def setup_config_dir
      unless Dir.exist?(CONFIG_DIR)
        FileUtils.mkdir_p(CONFIG_DIR)
      end

      unless File.exist?(PROMPT_FILE)
        # Check for bundled prompt file in the config directory
        config_prompt = File.join(File.dirname(__FILE__), '..', 'config', 'prompt')
        
        if File.exist?(config_prompt)
          puts "Copying bundled prompt file to #{PROMPT_FILE}"
          FileUtils.cp(config_prompt, PROMPT_FILE)
          puts "Prompt file installed successfully."
        else
          puts "Error: Prompt file not found at #{PROMPT_FILE}"
          puts "No bundled prompt file found at: #{config_prompt}"
          puts "Please create a prompt file with your custom prompt."
          exit 1 unless defined?(TESTING_MODE) && TESTING_MODE
        end
      end
    end

    def get_prompt
      # First check for repository-specific prompt
      if File.exist?(REPO_PROMPT_FILE)
        return File.read(REPO_PROMPT_FILE)
      end
      
      # Fall back to global prompt
      File.read(PROMPT_FILE)
    end

    def generate_code_review(diff)
      api_key = ENV['OPENROUTER_API_KEY']
      if api_key.nil? || api_key.empty?
        puts "❌ Error: OPENROUTER_API_KEY environment variable not set"
        puts ""
        puts "To get AI code reviews, you need an OpenRouter API key:"
        puts "1. Sign up at https://openrouter.ai/"
        puts "2. Get your API key from the dashboard"
        puts "3. Set it as an environment variable:"
        puts "   export OPENROUTER_API_KEY=\"sk-or-v1-your-key-here\""
        puts ""
        puts "For now, showing the raw diff instead:"
        puts "=" * 50
        return diff
      end

      model = ENV['GIT_REVIEW_MODEL'] || 'openai/gpt-4.1-mini'
      puts "Using model: #{model}" if ENV['DEBUG']
      
      prompt = get_prompt.gsub('{{DIFF}}', diff)
      puts "Prompt length: #{prompt.length} characters" if ENV['DEBUG']
      
      uri = URI.parse('https://openrouter.ai/api/v1/chat/completions')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{api_key}"
      request['HTTP-Referer'] = 'https://github.com/nitpicker-code-review'
      
      request_payload = {
        model: model,
        messages: [
          { role: 'user', content: prompt }
        ],
        max_tokens: 2000
      }
      
      request.body = request_payload.to_json
      puts "Making API request to OpenRouter..." if ENV['DEBUG']
      
      begin
        response = http.request(request)
        puts "API Response code: #{response.code}" if ENV['DEBUG']
        
        if response.code == '200'
          result = JSON.parse(response.body)
          puts "API Response parsed successfully" if ENV['DEBUG']
          
          if result['choices'] && result['choices'][0] && result['choices'][0]['message']
            review = result['choices'][0]['message']['content'].strip
            puts "Review length: #{review.length} characters" if ENV['DEBUG']
            puts "Review content preview: #{review[0..200]}..." if ENV['DEBUG']
            return review
          else
            puts "❌ Error: Unexpected API response structure"
            puts "Response: #{response.body}" if ENV['DEBUG']
            puts ""
            puts "Showing raw diff instead:"
            puts "=" * 50
            return diff
          end
        else
          error_body = JSON.parse(response.body) rescue response.body
          error_message = error_body.is_a?(Hash) && error_body['error'] ? error_body['error']['message'] || error_body['error'] : response.body
          
          puts "❌ API Error (#{response.code}): #{error_message}"
          
          if response.code == '401'
            puts ""
            puts "This usually means:"
            puts "• Your API key is invalid or expired"
            puts "• You haven't set the OPENROUTER_API_KEY environment variable"
            puts "• Your API key doesn't have sufficient credits"
            puts ""
            puts "Please check your API key at https://openrouter.ai/"
          elsif response.code == '429'
            puts ""
            puts "You've hit the rate limit. Please wait a moment and try again."
          end
          
          puts ""
          puts "Showing raw diff instead:"
          puts "=" * 50
          return diff
        end
      rescue JSON::ParserError => e
        puts "❌ Error parsing API response: #{e.message}"
        puts "Raw response: #{response.body}" if ENV['DEBUG']
        puts ""
        puts "Showing raw diff instead:"
        puts "=" * 50
        return diff
      rescue => e
        puts "❌ Error making API request: #{e.message}"
        puts ""
        puts "This could be due to:"
        puts "• Network connectivity issues"
        puts "• OpenRouter API service being temporarily unavailable"
        puts "• Invalid API configuration"
        puts ""
        puts "Showing raw diff instead:"
        puts "=" * 50
        return diff
      end
    end
  end
end