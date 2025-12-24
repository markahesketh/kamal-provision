# frozen_string_literal: true

require "kamal"
require "thor"

require_relative "provision/version"
require_relative "provision/commands/base"
require_relative "provision/commands/user"
require_relative "provision/configuration/ssh"
require_relative "provision/provisioner"
require_relative "provision/cli/base"
require_relative "provision/cli/main"
require_relative "provision/cli"

module Kamal
  module Provision
    class Error < StandardError; end
  end
end
