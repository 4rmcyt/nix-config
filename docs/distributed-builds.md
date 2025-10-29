# Distributed Builds Setup

This guide explains how to configure distributed builds between your desktop and homeserver.

## Overview

Distributed builds allow you to offload compilation tasks to remote machines, speeding up builds significantly. Your desktop can use the homeserver's CPU cores, and vice versa.

## Prerequisites

1. SSH access between machines
2. Nix installed on both machines
3. Sufficient disk space for Nix store on both machines

## Setup Steps

### 1. Generate SSH Keys for nix-builder User

On each machine that will act as a **client** (requesting builds), generate an SSH key for the root user:

```bash
sudo ssh-keygen -t ed25519 -f /root/.ssh/nix-builder -N "" -C "nix-builder@$(hostname)"
```

### 2. Get SSH Host Keys

On each machine that will act as a **builder** (accepting build requests), get the SSH host key:

```bash
ssh-keyscan -t ed25519 localhost
```

Save the output (the part after `localhost ssh-ed25519`).

For homeserver:
```bash
ssh-keyscan -t ed25519 192.168.1.165
```

For desktop:
```bash
ssh-keyscan -t ed25519 192.168.1.118
```

### 3. Configure Desktop to Use Homeserver as Builder

Add to `hosts/nixos/desktop/default.nix`:

```nix
{config, ...}: {
  # Enable distributed builds
  distributed-builds = {
    enable = true;
    role = "client"; # Desktop will send builds to homeserver

    builders = [
      {
        hostName = config.my.network.hosts.homeserver;
        system = "x86_64-linux";
        maxJobs = 8;  # Homeserver has 8 cores
        speedFactor = 2;  # Homeserver is faster
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        publicHostKey = "ssh-ed25519 AAAA..."; # Replace with actual key from step 2
      }
    ];
  };
}
```

### 4. Configure Homeserver to Accept Builds

Add to `hosts/nixos/homeserver/default.nix`:

```nix
{...}: {
  # Enable as builder
  distributed-builds = {
    enable = true;
    role = "builder";  # Homeserver accepts build requests
  };

  # Add desktop's public key to nix-builder user
  users.users.nix-builder.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA..."  # Replace with desktop's /root/.ssh/nix-builder.pub
  ];
}
```

### 5. Optionally: Configure Bidirectional Builds

Both machines can act as both client and builder:

```nix
{
  distributed-builds = {
    enable = true;
    role = "both";
    # ... builders configuration ...
  };
}
```

## Testing

Test the connection from desktop:

```bash
# As root
sudo ssh -i /root/.ssh/nix-builder nix-builder@192.168.1.165
```

Test a build:

```bash
nix build --builders 'ssh://nix-builder@192.168.1.165 x86_64-linux' nixpkgs#hello
```

## Monitoring

Check if remote builds are being used:

```bash
# On the client machine
journalctl -u nix-daemon -f | grep -i "will build on"
```

On the builder machine:

```bash
# Watch active builds
watch -n 1 'ps aux | grep nix-daemon'
```

## Troubleshooting

### Connection Issues

1. Verify SSH access:
   ```bash
   sudo ssh -i /root/.ssh/nix-builder nix-builder@<builder-hostname>
   ```

2. Check SSH host keys:
   ```bash
   sudo ssh-keyscan -t ed25519 <builder-hostname>
   ```

3. Verify nix-builder user exists on builder:
   ```bash
   id nix-builder
   ```

### Build Not Using Remote Builder

1. Check Nix daemon logs:
   ```bash
   sudo journalctl -u nix-daemon -n 100
   ```

2. Verify builder configuration:
   ```bash
   nix show-config | grep builders
   ```

3. Test with explicit builder:
   ```bash
   nix build --builders 'ssh://nix-builder@<builder-host> x86_64-linux' <package>
   ```

## Performance Tips

1. **Use substituters**: Enable `builders-use-substitutes` so builders can download from cache instead of building
2. **Adjust maxJobs**: Set based on available CPU cores
3. **speedFactor**: Set higher for more powerful machines to prioritize them
4. **Network**: Ensure good network connection between machines (wired is best)

## Security Considerations

1. The nix-builder user has limited permissions
2. SSH keys are used for authentication (no passwords)
3. Builds run in isolated environments
4. Consider using Tailscale for remote builds over the internet

## Example: Full Configuration

### Desktop (`hosts/nixos/desktop/default.nix`)

```nix
{config, ...}: {
  distributed-builds = {
    enable = true;
    role = "both";

    builders = [
      {
        hostName = config.my.network.hosts.homeserver;
        system = "x86_64-linux";
        maxJobs = 6;  # Use 6 of homeserver's 8 cores
        speedFactor = 1;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        publicHostKey = "ssh-ed25519 AAAA...";  # homeserver's key
      }
    ];
  };

  users.users.nix-builder.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA..."  # homeserver's /root/.ssh/nix-builder.pub
  ];
}
```

### Homeserver (`hosts/nixos/homeserver/default.nix`)

```nix
{config, ...}: {
  distributed-builds = {
    enable = true;
    role = "both";

    builders = [
      {
        hostName = config.my.network.hosts.desktop-lan;
        system = "x86_64-linux";
        maxJobs = 8;  # Use 8 of desktop's 12 cores
        speedFactor = 2;  # Desktop is faster
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
        publicHostKey = "ssh-ed25519 AAAA...";  # desktop's key
      }
    ];
  };

  users.users.nix-builder.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA..."  # desktop's /root/.ssh/nix-builder.pub
  ];
}
```

## References

- [NixOS Manual: Distributed Builds](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html)
- [Nix Pills: Remote Builds](https://nixos.org/guides/nix-pills/remote-builds.html)
