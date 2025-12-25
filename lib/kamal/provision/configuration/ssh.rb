# frozen_string_literal: true

module Kamal
  module Provision
    module Configuration
      class Ssh
        EXTENSION_KEY = :"x-provision"

        attr_reader :kamal_ssh, :provision_config

        def initialize(kamal_config)
          @kamal_ssh = kamal_config.ssh
          @provision_config = kamal_config.raw_config[EXTENSION_KEY] || {}
        end

        # Array of paths to public key files
        def public_key_paths
          Array(provision_config["keys"] || provision_config[:keys] || [])
        end

        # Array of raw public key strings
        def public_key_data
          Array(provision_config["key_data"] || provision_config[:key_data] || [])
        end

        # Combined array of all public keys (loaded from files + raw data)
        def public_keys
          keys_from_files = public_key_paths.map do |path|
            expanded = File.expand_path(path)
            unless File.exist?(expanded)
              raise Kamal::Provision::Error, "Public key file not found: #{path}"
            end
            File.read(expanded).strip
          end

          keys_from_files + public_key_data
        end

        # Whether to disable root login (defaults to true when user is not root)
        def disable_root_login?
          return false if user == "root"

          if provision_config.key?("disable_root_login")
            provision_config["disable_root_login"]
          elsif provision_config.key?(:disable_root_login)
            provision_config[:disable_root_login]
          else
            true
          end
        end

        # Whether to disable password authentication (defaults to true)
        def disable_password_authentication?
          if provision_config.key?("disable_password_authentication")
            provision_config["disable_password_authentication"]
          elsif provision_config.key?(:disable_password_authentication)
            provision_config[:disable_password_authentication]
          else
            true
          end
        end

        # Delegate everything else to Kamal's SSH config
        def method_missing(method, *args, &block)
          if kamal_ssh.respond_to?(method)
            kamal_ssh.send(method, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(method, include_private = false)
          kamal_ssh.respond_to?(method) || super
        end
      end
    end
  end
end
