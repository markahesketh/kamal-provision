# frozen_string_literal: true

require "test_helper"

module Kamal
  module Provision
    class ProvisionerTest < Minitest::Test
      def setup
        @provisioner = Kamal::Provision::Provisioner.new
      end

      def test_configured_returns_false_initially
        refute @provisioner.configured?
      end

      def test_configure_sets_config_kwargs
        @provisioner.configure(config_file: Pathname.new("config/deploy.yml"))

        assert @provisioner.configured?
      end

      def test_reset_clears_configuration
        @provisioner.configure(config_file: Pathname.new("config/deploy.yml"))
        @provisioner.reset

        refute @provisioner.configured?
      end

      def test_reset_restores_default_verbosity
        @provisioner.verbosity = :debug
        @provisioner.reset

        assert_equal :info, @provisioner.verbosity
      end

      def test_verbosity_defaults_to_info
        assert_equal :info, @provisioner.verbosity
      end

      def test_verbosity_can_be_set
        @provisioner.verbosity = :debug

        assert_equal :debug, @provisioner.verbosity
      end
    end
  end
end
