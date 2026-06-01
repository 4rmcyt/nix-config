# GCP Relay — Operations Guide

## Build & Deploy

```bash
nix build .#nixosConfigurations.gcp-relay.config.system.build.googleComputeImage

gsutil cp result/nixos-*.raw.tar.gz gs://gcp-relay-nixos-images/nixos-gcp-relay-vN.raw.tar.gz

gcloud compute images delete $(gcloud compute images list --filter="family=nixos-gcp-relay" --format="value(name)") --quiet

gcloud compute images create gcp-relay-$(date +%Y%m%d) \
  --source-uri gs://gcp-relay-nixos-images/nixos-gcp-relay-vN.raw.tar.gz \
  --family nixos-gcp-relay

gcloud compute instances delete gcp-relay --zone=us-central1-a --quiet

gcloud compute instances create gcp-relay \
  --image-family nixos-gcp-relay \
  --machine-type e2-micro \
  --zone us-central1-a \
  --boot-disk-size 30GB \
  --address gcp-relay-ip \
  --network-tier=STANDARD \
  --tags http-server,https-server

gsutil rm gs://gcp-relay-nixos-images/nixos-gcp-relay-vN.raw.tar.gz
```

## First Boot Setup

After VM is up, copy the age key and activate secrets:

```bash
gcloud compute scp ~/.config/sops/age/keys.txt gcp-relay:/tmp/keys.txt --zone=us-central1-a
```

On the VM:
```bash
sudo mkdir -p /root/.config/sops/age
sudo mv /tmp/keys.txt /root/.config/sops/age/keys.txt
sudo chmod 600 /root/.config/sops/age/keys.txt
sudo /run/current-system/activate
sudo systemctl restart headscale caddy
```

## Ongoing Deploys (after first boot)

```bash
nixos-rebuild switch --flake .#gcp-relay --target-host zeev@gcp-relay --use-remote-sudo --build-host localhost
```

## Key Facts

- **IP**: 35.209.0.21 (static, reserved as `gcp-relay-ip`)
- **Zone**: us-central1-a
- **Machine**: e2-micro (free tier)
- **GCS bucket**: gcp-relay-nixos-images
- **SSH host key**: fixed in `secrets/gcp-relay-host-ed25519` — same fingerprint across rebuilds
- **Age key fingerprint**: age1fsjqjx77t6yhfvdgq8a69aggh36jv0fjm53u26tlqvs73lkpgutsssdttd
