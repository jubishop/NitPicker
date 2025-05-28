require 'rake/testtask'
require 'fileutils'
require_relative 'lib/nitpicker/version'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

desc 'Build the gem and place it in the gemspec/ folder'
task :build do
  # Build the gem
  sh "gem build gemspec/nitpicker.gemspec"
  
  # Get the version
  version = NitPicker::VERSION
  
  # Move the gem file to the gemspec/ folder
  gem_file = "nitpicker-code-review-#{version}.gem"
  if File.exist?(gem_file)
    FileUtils.mv(gem_file, "gemspec/#{gem_file}")
    puts "Successfully built and moved #{gem_file} to gemspec/ folder"
  else
    puts "Error: Could not find #{gem_file}"
  end
end

desc 'Build, install and test the gem'
task install: :build do
  version = NitPicker::VERSION
  gem_file = "gemspec/nitpicker-code-review-#{version}.gem"
  sh "gem install #{gem_file}"
end

desc 'Build and push the gem to RubyGems'
task push: :build do
  version = NitPicker::VERSION
  gem_file = "gemspec/nitpicker-code-review-#{version}.gem"
  
  puts "Pushing nitpicker-code-review version #{version} to RubyGems..."
  begin
    sh "gem push #{gem_file}"
    puts "Successfully pushed #{gem_file} to RubyGems"
  rescue => e
    puts "Error pushing gem to RubyGems: #{e.message}"
    puts "Hint: Make sure you're logged in to RubyGems with 'gem signin'"
    exit 1
  end
end

task default: :test