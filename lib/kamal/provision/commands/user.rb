# frozen_string_literal: true

module Kamal
  module Provision
    module Commands
      class User < Base
        def user_exists?(username)
          [:id, username]
        end

        def create_user(username)
          [:sudo, :useradd, "--create-home", "--shell", "/bin/bash", username]
        end

        def ensure_ssh_directory(username)
          home_dir = "/home/#{username}"
          ssh_dir = "#{home_dir}/.ssh"
          authorized_keys = "#{ssh_dir}/authorized_keys"

          combine(
            [:sudo, :mkdir, "-p", ssh_dir],
            [:sudo, :touch, authorized_keys],
            [:sudo, :chmod, "700", ssh_dir],
            [:sudo, :chmod, "600", authorized_keys],
            [:sudo, :chown, "-R", "#{username}:#{username}", ssh_dir]
          )
        end

        def add_public_key(username, public_key)
          authorized_keys = "/home/#{username}/.ssh/authorized_keys"
          # Escape single quotes in the key
          escaped_key = public_key.gsub("'", "'\\\\''")

          # Only add if not already present
          [
            :sudo, :sh, "-c",
            "grep -qxF '#{escaped_key}' #{authorized_keys} || echo '#{escaped_key}' | sudo tee -a #{authorized_keys} > /dev/null"
          ]
        end

        def add_to_docker_group(username)
          [:sudo, :usermod, "-a", "-G", "docker", username]
        end
      end
    end
  end
end
