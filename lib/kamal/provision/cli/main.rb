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

        private

        def provision_users
          hosts = PROVISIONER.config.all_hosts
          user = PROVISIONER.config.ssh.user
          public_keys = PROVISIONER.ssh_config.public_keys

          if public_keys.empty?
            raise ProvisionError, "No public keys configured. Set x-provision.keys or x-provision.key_data in config/deploy.yml"
          end

          say "Creating user '#{user}' on #{hosts.size} host(s)...", :magenta

          hosts.each do |host|
            provision_user_on_host(host, user, public_keys)
          end
        end

        def provision_user_on_host(host, user, public_keys)
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

            # Add public keys
            public_keys.each do |key|
              execute(*user_cmd.add_public_key(user, key))
            end

            # Add to docker group
            info "Adding #{user} to docker group..."
            execute(*user_cmd.add_to_docker_group(user))
          end

          say "    Done provisioning #{host}", :green
        end

        def establish_connection(host, user)
          ssh_options = PROVISIONER.config.ssh.options

          # Try connecting as configured user first
          begin
            ssh_host = build_ssh_host(host, user, ssh_options)
            test_connection(ssh_host)
            say "    Connected as #{user}@#{host}", :magenta
            return [ssh_host, user]
          rescue SSHKit::Runner::ExecuteError => e
            if e.cause.is_a?(Net::SSH::AuthenticationFailed) || e.cause.is_a?(Errno::ECONNREFUSED)
              say "    Could not connect as #{user}, falling back to root...", :yellow
            else
              raise
            end
          end

          # Fall back to root for initial provisioning
          ssh_host = build_ssh_host(host, "root", ssh_options)
          test_connection(ssh_host)
          say "    Connected as root@#{host} (initial provisioning)", :magenta
          [ssh_host, "root"]
        end

        def build_ssh_host(host, user, ssh_options)
          SSHKit::Host.new(host).tap do |h|
            h.user = user
            h.ssh_options = ssh_options.except(:user)
          end
        end

        def test_connection(ssh_host)
          on(ssh_host) do
            test("true")
          end
        end
      end
    end
  end
end
