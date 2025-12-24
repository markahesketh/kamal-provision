# frozen_string_literal: true

require "thor"
require "kamal/sshkit_with_ext"

module Kamal
  module Provision
    module Cli
      class Base < Thor
        include SSHKit::DSL

        def self.exit_on_failure?
          true
        end

        class_option :verbose, type: :boolean, aliases: "-v", desc: "Detailed logging"
        class_option :quiet, type: :boolean, aliases: "-q", desc: "Minimal logging"
        class_option :config_file, aliases: "-c", default: "config/deploy.yml",
                     desc: "Path to config file"
        class_option :destination, aliases: "-d",
                     desc: "Specify destination (staging -> deploy.staging.yml)"

        private

        def initialize_provisioner
          PROVISIONER.tap do |provisioner|
            if options[:verbose]
              ENV["VERBOSE"] = "1"
              provisioner.verbosity = :debug
            end

            if options[:quiet]
              provisioner.verbosity = :error
            end

            provisioner.configure(
              config_file: Pathname.new(File.expand_path(options[:config_file])),
              destination: options[:destination]
            )
          end
        end

        def say(message, color = nil)
          color_code = case color
                       when :magenta then "\e[35m"
                       when :green then "\e[32m"
                       when :red then "\e[31m"
                       when :yellow then "\e[33m"
                       else ""
                       end
          reset = color ? "\e[0m" : ""
          puts "#{color_code}#{message}#{reset}"
        end
      end
    end
  end
end
