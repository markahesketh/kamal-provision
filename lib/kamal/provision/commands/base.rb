# frozen_string_literal: true

module Kamal
  module Provision
    module Commands
      class Base
        attr_reader :config

        def initialize(config)
          @config = config
        end

        private

        def combine(*commands, by: "&&")
          commands
            .compact
            .collect { |command| Array(command) + [by] }.flatten
            .tap { |combined| combined.pop }
        end

        def pipe(*commands)
          combine(*commands, by: "|")
        end
      end
    end
  end
end
