{ config, pkgs, ... }:

{
  # Script to configure YubiKey authentication in Keycloak
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "setup-keycloak-yubikey" ''
      #!/bin/bash
      
      # Keycloak admin CLI setup
      KEYCLOAK_URL="https://keycloak.example.com"
      REALM_NAME="master"  # Change to your realm name
      
      echo "Setting up YubiKey authentication for Keycloak..."
      
      # Wait for Keycloak to be ready
      until curl -f -s "$KEYCLOAK_URL/health/ready" > /dev/null; do
        echo "Waiting for Keycloak to be ready..."
        sleep 5
      done
      
      echo "Keycloak is ready. Please complete the following steps manually:"
      echo ""
      echo "1. Log into Keycloak Admin Console: $KEYCLOAK_URL"
      echo "2. Go to your realm -> Authentication -> Required Actions"
      echo "3. Enable 'Webauthn Register' and 'Webauthn Register Passwordless'"
      echo "4. Go to Authentication -> Flows"
      echo "5. Create a new flow or copy 'Browser' flow"
      echo "6. Add 'WebAuthn Authenticator' execution"
      echo "7. Set it as 'Alternative' or 'Required'"
      echo "8. Go to Authentication -> Bindings"
      echo "9. Set your new flow as the Browser Flow"
      echo ""
      echo "For users to register YubiKeys:"
      echo "1. Users should log in normally"
      echo "2. Go to Account Console -> Security -> Signing In"
      echo "3. Set up 'Security Key' authentication"
      echo ""
      echo "YubiKey setup script completed!"
    '')
  ];
}