# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class Kamal::Provision::Cli::MainTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @config_path = File.join(@tmpdir, "deploy.yml")
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_init_adds_x_provision_to_config
    File.write(@config_path, <<~YAML)
      service: myapp
      image: myapp
    YAML

    capture_io do
      Kamal::Provision::Cli::Main.start(["init", "-c", @config_path])
    end

    content = File.read(@config_path)
    assert_includes content, "x-provision:"
    assert_includes content, "~/.ssh/id_rsa.pub"
  end

  def test_init_errors_when_config_file_not_found
    missing_path = File.join(@tmpdir, "missing.yml")

    error = assert_raises(Kamal::Provision::Cli::ProvisionError) do
      capture_io do
        Kamal::Provision::Cli::Main.start(["init", "-c", missing_path])
      end
    end

    assert_includes error.message, "Config file not found"
  end

  def test_init_skips_when_x_provision_already_exists
    File.write(@config_path, <<~YAML)
      service: myapp
      x-provision:
        keys:
          - ~/.ssh/existing.pub
    YAML

    original_content = File.read(@config_path)

    output, = capture_io do
      Kamal::Provision::Cli::Main.start(["init", "-c", @config_path])
    end

    assert_includes output, "already exists"
    assert_equal original_content, File.read(@config_path)
  end
end
