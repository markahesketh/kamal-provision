# frozen_string_literal: true

module Kamal
  module Provision
    class Provisioner
      attr_accessor :verbosity
      attr_reader :config_kwargs

      def initialize
        reset
      end

      def reset
        @verbosity = :info
        @config = nil
        @config_kwargs = nil
        @ssh_config = nil
        @commands = {}
      end

      def config
        @config ||= Kamal::Configuration.create_from(**@config_kwargs.to_h).tap do |config|
          @config_kwargs = nil
          configure_sshkit_with(config)
        end
      end

      def configure(**kwargs)
        @config = nil
        @config_kwargs = kwargs
      end

      def configured?
        @config || @config_kwargs
      end

      # Our extended SSH configuration with public keys
      def ssh_config
        @ssh_config ||= Configuration::Ssh.new(config)
      end

      # Command generators
      def user
        @commands[:user] ||= Commands::User.new(config)
      end

      private

      def configure_sshkit_with(config)
        SSHKit::Backend::Netssh.pool.idle_timeout = config.sshkit.pool_idle_timeout
        SSHKit::Backend::Netssh.configure do |sshkit|
          sshkit.max_concurrent_starts = config.sshkit.max_concurrent_starts
          sshkit.ssh_options = config.ssh.options
        end
        SSHKit.config.output_verbosity = verbosity
      end
    end
  end
end
