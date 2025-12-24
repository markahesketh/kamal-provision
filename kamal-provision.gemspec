# frozen_string_literal: true

require_relative "lib/kamal/provision/version"

Gem::Specification.new do |spec|
  spec.name = "kamal-provision"
  spec.version = Kamal::Provision::VERSION
  spec.authors = ["Mark Hesketh"]
  spec.email = ["contact@markhesketh.co.uk"]

  spec.summary = "Provision servers for Kamal deployments"
  spec.homepage = "https://github.com/markahesketh/kamal-provision"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/markahesketh/kamal-provision"
  spec.metadata["changelog_uri"] = "https://github.com/markahesketh/kamal-provision/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = ["kamal-provision"]
  spec.require_paths = ["lib"]

  spec.add_dependency "kamal", ">= 2.0"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "sshkit", "~> 1.21"
end
