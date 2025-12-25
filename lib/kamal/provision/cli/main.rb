# frozen_string_literal: true

module Kamal
  module Provision
    module Cli
      class Main < Base
        desc "provision", "Provision all servers"
        def provision
          initialize_provisioner

          say "Provisioning servers...", :magenta

          if PROVISIONER.config.ssh.user == "root"
            say "Skipping user creation: ssh.user is root", :yellow
            return
          end

          provision_users

          say "Provisioning complete!", :green
        end

        desc "version", "Show kamal-provision version"
        def version
          puts Kamal::Provision::VERSION
        end

        desc "init", "Initialize x-provision configuration in deploy config"
        def init
          config_path = options[:config_file]

          unless File.exist?(config_path)
            raise ProvisionError, "Config file not found: #{config_path}"
          end

          content = File.read(config_path)

          if content.match?(/^x-provision:/m)
            say "x-provision already exists in #{config_path}", :yellow
            return
          end

          provision_block = <<~YAML

            x-provision:
              keys:
                - ~/.ssh/id_rsa.pub
          YAML

          File.write(config_path, content + provision_block)
          say "Added x-provision configuration to #{config_path}", :green
        end

        private

        def provision_users
          hosts = PROVISIONER.config.all_hosts
          user = PROVISIONER.config.ssh.user
          configured_keys = PROVISIONER.ssh_config.public_keys

          say "Creating user '#{user}' on #{hosts.size} host(s)...", :magenta

          hosts.each do |host|
            provision_user_on_host(host, user, configured_keys)
          end
        end

        def provision_user_on_host(host, user, configured_keys)
          say "  Provisioning #{host}...", :magenta

          ssh_host, _connected_as = establish_connection(host, user)

          on(ssh_host) do
            user_cmd = PROVISIONER.user

            # Check if user exists
            unless test(*user_cmd.user_exists?(user))
              info "Creating user #{user}..."
              execute(*user_cmd.create_user(user))
            end

            # Ensure .ssh directory exists with correct permissions
            execute(*user_cmd.ensure_ssh_directory(user))

            # Determine which keys to use
            public_keys = configured_keys
            if public_keys.empty?
              # Check if user already has authorized_keys
              if test(*user_cmd.has_authorized_keys?(user))
                info "User #{user} already has authorized_keys, skipping key setup"
              else
                # Use root's authorized_keys as default
                info "No keys configured, using root's authorized_keys..."
                root_keys = capture(*user_cmd.read_authorized_keys("root")).strip
                if root_keys.empty?
                  raise ProvisionError, "No public keys configured and root has no authorized_keys"
                end
                public_keys = root_keys.split("\n").map(&:strip).reject(&:empty?)
              end
            end

            # Add public keys
            public_keys.each do |key|
              execute(*user_cmd.add_public_key(user, key))
            end

            # Add to docker group
            info "Adding #{user} to docker group..."
            execute(*user_cmd.add_to_docker_group(user))
          end

          # Harden SSH configuration (only if keys were configured to avoid lockout)
          if configured_keys.empty?
            say "    Skipping SSH hardening: no SSH keys configured", :yellow
          else
            harden_ssh(ssh_host, host)
          end

          say "    Done provisioning #{host}", :green
        end

        def establish_connection(host, user)
          ssh_options = PROVISIONER.config.ssh.options
          configured_port = ssh_options[:port] || 22

          # Try combinations: configured user first, then root; configured port first, then 22
          attempts = [
            { user: user, port: configured_port },
            ({ user: user, port: 22 } if configured_port != 22),
            { user: "root", port: configured_port },
            ({ user: "root", port: 22 } if configured_port != 22)
          ].compact

          attempts.each_with_index do |attempt, index|
            begin
              ssh_host = build_ssh_host(host, attempt[:user], attempt[:port], ssh_options)
              test_connection(ssh_host)
              say "    Connected as #{attempt[:user]}@#{host}:#{attempt[:port]}", :magenta
              return [ssh_host, attempt[:user]]
            rescue SSHKit::Runner::ExecuteError => e
              if e.cause.is_a?(Net::SSH::AuthenticationFailed) || e.cause.is_a?(Errno::ECONNREFUSED)
                if index < attempts.size - 1
                  next_attempt = attempts[index + 1]
                  say "    Could not connect as #{attempt[:user]}@#{host}:#{attempt[:port]}, trying #{next_attempt[:user]}@#{host}:#{next_attempt[:port]}...", :yellow
                else
                  raise
                end
              else
                raise
              end
            end
          end
        end

        def build_ssh_host(host, user, port, ssh_options)
          SSHKit::Host.new(host).tap do |h|
            h.user = user
            h.port = port
            h.ssh_options = ssh_options.except(:user, :port)
          end
        end

        def test_connection(ssh_host)
          on(ssh_host) do
            test("true")
          end
        end

        def harden_ssh(ssh_host, host)
          ssh_config = PROVISIONER.ssh_config
          user_cmd = PROVISIONER.user

          on(ssh_host) do
            changes_made = false

            if ssh_config.disable_root_login?
              info "Disabling root SSH login..."
              execute(*user_cmd.disable_root_login)
              changes_made = true
            end

            if ssh_config.disable_password_authentication?
              info "Disabling password authentication..."
              execute(*user_cmd.disable_password_authentication)
              changes_made = true
            end

            if changes_made
              info "Restarting SSH service..."
              execute(*user_cmd.restart_sshd)
            end
          end
        rescue SSHKit::Runner::ExecuteError => e
          raise ProvisionError, "Failed to harden SSH on #{host}: #{e.message}. Ensure key-based SSH access works before retrying."
        end
      end
    end
  end
end
