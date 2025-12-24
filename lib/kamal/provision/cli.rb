# frozen_string_literal: true

module Kamal
  module Provision
    module Cli
      class ProvisionError < StandardError; end
    end

    # Global provisioner instance (following Kamal's KAMAL pattern)
    PROVISIONER = Kamal::Provision::Provisioner.new
  end
end
