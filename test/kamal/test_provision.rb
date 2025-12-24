# frozen_string_literal: true

require "test_helper"

module Kamal
  class TestProvision < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Kamal::Provision::VERSION
    end

    def test_error_class_exists
      assert_kind_of Class, Kamal::Provision::Error
      assert Kamal::Provision::Error < StandardError
    end
  end
end
