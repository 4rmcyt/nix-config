# GCP Relay — Operations Guide

## Key Facts

| Property       | Value                                                                |
|----------------|----------------------------------------------------------------------|
| IP             | 203.0.113.1 (static, reserved as `gcp-relay-ip`)                    |
| Zone           | us-central1-a                                                        |
| Machine        | e2-micro (free tier)                                                 |
| GCS bucket     | gcp-relay-nixos-images                                               |
| SSH host key   | `secrets/gcp-relay-host-ed25519` — fixed fingerprint across rebuilds |
| Age key        | `age1fsjqjx77t6yhfvdgq8a69aggh36jv0fjm53u26tlqvs73lkpgutsssdttd`   |
| Tofu config    | `infra/tf/gcp-relay/`                                                |

---

## Full Rebuild (new image)

### 1. Build the GCP image

```bash
nh os build-image --image-variant google-compute --hostname gcp-relay ~/src/nix-config
```

### 2. Upload to GCS

```bash
gsutil cp result/nixos-*.raw.tar.gz gs://gcp-relay-nixos-images/nixos-gcp-relay-v$(date +%Y%m%d).raw.tar.gz
```

### 3. Register image & recreate VM

**Option A — OpenTofu (recommended):**
```bash
cd infra/tf/gcp-relay
tofu apply -var="image_date=$(date +%Y%m%d)"
```

**Option B — gcloud:**
```bash
gcloud compute images delete \
  $(gcloud compute images list --filter="family=nixos-gcp-relay" --format="value(name)") \
  --quiet

gcloud compute images create gcp-relay-$(date +%Y%m%d) \
  --source-uri gs://gcp-relay-nixos-images/nixos-gcp-relay-v$(date +%Y%m%d).raw.tar.gz \
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
```

### 4. Cleanup

```bash
gsutil rm gs://gcp-relay-nixos-images/nixos-gcp-relay-v$(date +%Y%m%d).raw.tar.gz
```

---

## First Boot Setup

After the VM is up, copy the age key and activate secrets:

```bash
gcloud compute scp ~/.config/sops/age/keys.txt gcp-relay:/tmp/keys.txt --zone=us-central1-a
```

On the VM:

```bash
sudo mkdir -p /root/.config/sops/age
sudo mv /tmp/keys.txt /root/.config/sops/age/keys.txt
sudo chmod 600 /root/.config/sops/age/keys.txt
sudo /run/current-system/activate
sudo systemctl restart headscale headplane caddy
```

---

## Ongoing Deploys

```bash
nh os switch --hostname gcp-relay --target-host zeev@gcp-relay --elevation-strategy passwordless ~/src/nix-config
```

---

## Tofu Setup (first time)

```bash
cd infra/tf/gcp-relay
tofu init
gcloud auth application-default login
```
