# frozen_string_literal: true

require "test_helper"

class Kamal::Provision::Commands::UserTest < Minitest::Test
  def setup
    @config = mock_config
    @user = Kamal::Provision::Commands::User.new(@config)
  end

  def test_user_exists_returns_id_command
    result = @user.user_exists?("deploy")

    assert_equal [:id, "deploy"], result
  end

  def test_create_user_returns_useradd_command
    result = @user.create_user("deploy")

    assert_equal [:sudo, :useradd, "--create-home", "--shell", "/bin/bash", "deploy"], result
  end

  def test_ensure_ssh_directory_creates_directory_with_correct_permissions
    result = @user.ensure_ssh_directory("deploy")

    assert_includes result, :sudo
    assert_includes result, :mkdir
    assert_includes result, "/home/deploy/.ssh"
    assert_includes result, "700"
    assert_includes result, "600"
    assert_includes result, "deploy:deploy"
  end

  def test_add_public_key_uses_grep_to_check_existing
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI test@example.com"
    result = @user.add_public_key("deploy", key)

    assert_equal :sudo, result[0]
    assert_equal :sh, result[1]
    assert_equal "-c", result[2]
    assert_includes result[3], "grep -qxF"
    assert_includes result[3], "/home/deploy/.ssh/authorized_keys"
    assert_includes result[3], key
  end

  def test_add_public_key_escapes_single_quotes
    key = "ssh-ed25519 key'with'quotes"
    result = @user.add_public_key("deploy", key)

    # Single quotes should be escaped
    assert_includes result[3], "key'\\''with'\\''quotes"
  end

  def test_add_to_docker_group_returns_usermod_command
    result = @user.add_to_docker_group("deploy")

    assert_equal [:sudo, :usermod, "-a", "-G", "docker", "deploy"], result
  end

  def test_read_authorized_keys_for_root
    result = @user.read_authorized_keys("root")

    assert_equal [:cat, "/root/.ssh/authorized_keys"], result
  end

  def test_read_authorized_keys_for_non_root_user
    result = @user.read_authorized_keys("deploy")

    assert_equal [:sudo, :cat, "/home/deploy/.ssh/authorized_keys"], result
  end

  def test_has_authorized_keys_for_root
    result = @user.has_authorized_keys?("root")

    assert_equal [:test, "-s", "/root/.ssh/authorized_keys"], result
  end

  def test_has_authorized_keys_for_non_root_user
    result = @user.has_authorized_keys?("deploy")

    assert_equal [:test, "-s", "/home/deploy/.ssh/authorized_keys"], result
  end

  def test_disable_root_login_modifies_sshd_config
    result = @user.disable_root_login

    assert_equal :sudo, result[0]
    assert_equal :sh, result[1]
    assert_equal "-c", result[2]
    assert_includes result[3], "PermitRootLogin no"
    assert_includes result[3], "/etc/ssh/sshd_config"
  end

  def test_disable_password_authentication_modifies_sshd_config
    result = @user.disable_password_authentication

    assert_equal :sudo, result[0]
    assert_equal :sh, result[1]
    assert_equal "-c", result[2]
    assert_includes result[3], "PasswordAuthentication no"
    assert_includes result[3], "/etc/ssh/sshd_config"
  end

  def test_restart_sshd_tries_multiple_service_names
    result = @user.restart_sshd

    assert_equal :sudo, result[0]
    assert_equal :sh, result[1]
    assert_equal "-c", result[2]
    assert_includes result[3], "systemctl restart sshd"
    assert_includes result[3], "systemctl restart ssh"
    assert_includes result[3], "service ssh restart"
    assert_includes result[3], "service sshd restart"
  end

  private

  def mock_config
    Object.new
  end
end
