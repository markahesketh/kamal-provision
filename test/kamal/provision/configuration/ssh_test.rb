# frozen_string_literal: true

require "test_helper"
require "tempfile"

module Kamal
  module Provision
    module Configuration
      class SshTest < Minitest::Test
        def test_public_key_paths_returns_empty_array_when_not_configured
          ssh_config = build_ssh_config({})

          assert_equal [], ssh_config.public_key_paths
        end

        def test_public_key_paths_returns_configured_paths
          paths = ["~/.ssh/id_ed25519.pub", "~/.ssh/other.pub"]
          ssh_config = build_ssh_config("keys" => paths)

          assert_equal paths, ssh_config.public_key_paths
        end

        def test_public_key_data_returns_empty_array_when_not_configured
          ssh_config = build_ssh_config({})

          assert_equal [], ssh_config.public_key_data
        end

        def test_public_key_data_returns_configured_keys
          keys = ["ssh-ed25519 AAAAC3... user@host"]
          ssh_config = build_ssh_config("key_data" => keys)

          assert_equal keys, ssh_config.public_key_data
        end

        def test_public_keys_loads_keys_from_files
          key_content = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI test@example.com"

          Tempfile.create("test_key.pub") do |file|
            file.write(key_content)
            file.flush

            ssh_config = build_ssh_config("keys" => [file.path])

            assert_equal [key_content], ssh_config.public_keys
          end
        end

        def test_public_keys_strips_whitespace_from_file_content
          key_content = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI test@example.com"

          Tempfile.create("test_key.pub") do |file|
            file.write("  #{key_content}  \n")
            file.flush

            ssh_config = build_ssh_config("keys" => [file.path])

            assert_equal [key_content], ssh_config.public_keys
          end
        end

        def test_public_keys_combines_file_keys_and_raw_data
          key_from_file = "ssh-ed25519 file-key"
          key_from_data = "ssh-ed25519 data-key"

          Tempfile.create("test_key.pub") do |file|
            file.write(key_from_file)
            file.flush

            ssh_config = build_ssh_config(
              "keys" => [file.path],
              "key_data" => [key_from_data]
            )

            assert_equal [key_from_file, key_from_data], ssh_config.public_keys
          end
        end

        def test_public_keys_raises_error_when_file_not_found
          ssh_config = build_ssh_config("keys" => ["/nonexistent/key.pub"])

          error = assert_raises(Kamal::Provision::Error) do
            ssh_config.public_keys
          end

          assert_includes error.message, "Public key file not found"
          assert_includes error.message, "/nonexistent/key.pub"
        end

        def test_delegates_to_kamal_ssh_config
          kamal_ssh = MockKamalSsh.new("deploy")
          kamal_config = MockKamalConfig.new({}, kamal_ssh)
          ssh_config = Kamal::Provision::Configuration::Ssh.new(kamal_config)

          assert_equal "deploy", ssh_config.user
        end

        def test_respond_to_delegates_to_kamal_ssh
          kamal_ssh = MockKamalSsh.new("deploy")
          kamal_config = MockKamalConfig.new({}, kamal_ssh)
          ssh_config = Kamal::Provision::Configuration::Ssh.new(kamal_config)

          assert ssh_config.respond_to?(:user)
          refute ssh_config.respond_to?(:nonexistent_method)
        end

        private

        def build_ssh_config(provision_config)
          kamal_ssh = Object.new
          kamal_config = MockKamalConfig.new(provision_config, kamal_ssh)
          Kamal::Provision::Configuration::Ssh.new(kamal_config)
        end

        class MockKamalConfig
          attr_reader :ssh, :raw_config

          def initialize(provision_config, kamal_ssh = Object.new)
            @ssh = kamal_ssh
            @raw_config = { "x-provision": provision_config }
          end
        end

        class MockKamalSsh
          attr_reader :user

          def initialize(user)
            @user = user
          end
        end
      end
    end
  end
end
