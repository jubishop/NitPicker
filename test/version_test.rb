require_relative 'test_helper'
require_relative '../lib/nitpicker/version'

class VersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil NitPicker::VERSION
    assert_instance_of String, NitPicker::VERSION
  end

  def test_version_format
    # Test semantic versioning format (e.g., "1.0.0")
    assert_match(/\A\d+\.\d+\.\d+\z/, NitPicker::VERSION)
  end

  def test_version_consistency_with_gemspec
    gemspec_path = File.join(__dir__, '../gemspec/nitpicker.gemspec')
    gemspec_content = File.read(gemspec_path)
    
    # The gemspec should reference NitPicker::VERSION
    assert_includes gemspec_content, 'NitPicker::VERSION'
  end

  def test_version_file_exists
    version_file = File.join(__dir__, '../lib/nitpicker/version.rb')
    assert File.exist?(version_file), "Version file should exist at #{version_file}"
  end

  def test_version_file_content
    version_file = File.join(__dir__, '../lib/nitpicker/version.rb')
    content = File.read(version_file)
    
    assert_includes content, 'module NitPicker'
    assert_includes content, 'VERSION ='
    assert_includes content, NitPicker::VERSION
  end
end