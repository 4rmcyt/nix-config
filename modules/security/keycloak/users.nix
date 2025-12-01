{
  config,
  pkgs,
  lib,
  ...
}: let
  # Keycloak Admin CLI wrapper script
  kcadm = "${pkgs.keycloak}/bin/kcadm.sh";

  # User definitions - add your users here
  users = [
    {
      username = "zeev";
      email = config.my.defaults.email;
      firstName = "Zeev";
      lastName = "";
      groups = ["Admins" "Users" "Grafana Admins"];
      enabled = true;
    }
    # Add more users as needed:
    # {
    #   username = "another-user";
    #   email = "user@example.com";
    #   firstName = "First";
    #   lastName = "Last";
    #   groups = ["Users"];
    #   enabled = true;
    # }
  ];

  # Generate kcadm commands for user creation
  createUserCommands = lib.concatMapStringsSep "\n" (user: ''
    # Check if user exists
    USER_ID=$(${kcadm} get users -r homelab -q username="${user.username}" --fields id --format csv --noquotes 2>/dev/null || true)

    if [ -z "$USER_ID" ]; then
      echo "Creating user: ${user.username}"
      ${kcadm} create users -r homelab \
        -s username="${user.username}" \
        -s email="${user.email}" \
        -s firstName="${user.firstName}" \
        -s lastName="${user.lastName}" \
        -s enabled=${if user.enabled then "true" else "false"} \
        -s emailVerified=true

      # Get the newly created user ID
      USER_ID=$(${kcadm} get users -r homelab -q username="${user.username}" --fields id --format csv --noquotes)

      # Set temporary password (user must change on first login)
      echo "Setting temporary password for ${user.username}"
      ${kcadm} set-password -r homelab --username "${user.username}" --new-password "ChangeMe123!" --temporary
    else
      echo "User ${user.username} already exists (ID: $USER_ID)"
    fi

    # Assign groups
    ${lib.concatMapStringsSep "\n    " (group: ''
      GROUP_ID=$(${kcadm} get groups -r homelab -q name="${group}" --fields id --format csv --noquotes 2>/dev/null || true)
      if [ -n "$GROUP_ID" ]; then
        echo "Adding ${user.username} to group: ${group}"
        ${kcadm} update users/$USER_ID/groups/$GROUP_ID -r homelab -s realm=homelab -s userId=$USER_ID -s groupId=$GROUP_ID -n 2>/dev/null || true
      fi
    '') user.groups}
  '') users;

in {
  # SOPS secret for Keycloak admin password (already defined in default.nix)
  # We'll use it here for authentication

  # Systemd service to create users
  systemd.services.keycloak-setup-users = {
    description = "Setup Keycloak users and groups";
    wantedBy = ["multi-user.target"];
    after = ["keycloak.service"];
    requires = ["keycloak.service"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "keycloak";
      Group = "keycloak";
      # Allow reading admin password
      LoadCredential = [
        "admin_password:${config.sops.secrets.keycloak_admin_password.path}"
      ];
    };

    script = ''
      set -e

      # Wait for Keycloak to be fully ready
      echo "Waiting for Keycloak to be ready..."
      for i in {1..60}; do
        if curl -sf http://127.0.0.1:9000/realms/homelab >/dev/null 2>&1; then
          echo "Keycloak is ready!"
          break
        fi
        if [ $i -eq 60 ]; then
          echo "Timeout waiting for Keycloak"
          exit 1
        fi
        sleep 2
      done

      # Get admin password
      ADMIN_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/admin_password")

      # Configure kcadm
      export KC_OPTS="-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts"

      # Authenticate as admin
      echo "Authenticating as admin..."
      ${kcadm} config credentials \
        --server http://127.0.0.1:9000 \
        --realm master \
        --user admin \
        --password "$ADMIN_PASSWORD"

      # Create users and assign groups
      ${createUserCommands}

      echo "User setup complete!"
    '';
  };
}
