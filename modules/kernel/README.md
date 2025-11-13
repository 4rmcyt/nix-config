# Kernel Optimization with modprobed-db

This module provides automatic kernel module tracking and optional kernel optimization using modprobed-db.

## Features

- **Automatic Module Tracking**: Systemd service runs hourly to track loaded kernel modules
- **Kernel Optimization**: Optional custom kernel builds using only the modules you actually use
- **Compiler Options**: Support for both GCC and Clang
- **CPU Optimization**: Native and specific CPU architecture targeting

## Configuration

### Basic Setup (Module Tracking Only)

The module tracking is enabled by default when you import this module. It will:
- Run hourly to track loaded modules
- Store data in `/var/lib/modprobed-db/.config/modprobed-db/modprobed.db`
- Start 5 minutes after boot and then run every hour

```nix
services.modprobed-db = {
  enable = true;
  user = "root";
};
```

### Advanced: Kernel Optimization

After collecting module data for a few weeks, you can use it to optimize your kernel builds.

**Option 1: Show Optimization Instructions**
```nix
my.kernel.optimized.enable = true;
```
This will display instructions on how to use your collected module data.

**Option 2: Manual Kernel Configuration**
Use the modprobed.db file with CachyOS kernel configurator or other kernel build tools to only compile the modules you actually use.

## Usage

### Manual Commands

```bash
# View tracked modules
modprobed-db list

# Manually store current modules
sudo modprobed-db store

# View the database file
cat /var/lib/modprobed-db/.config/modprobed-db/modprobed.db
```

### Systemd Service Management

```bash
# Check service status
systemctl status modprobed-db.timer
systemctl status modprobed-db.service

# View service logs
journalctl -u modprobed-db.service

# Manually trigger the service
sudo systemctl start modprobed-db.service

# Stop the timer (not recommended)
sudo systemctl stop modprobed-db.timer
```

### Checking Module Collection Progress

```bash
# Count tracked modules
wc -l /var/lib/modprobed-db/.config/modprobed-db/modprobed.db

# See when modules were last updated
sudo journalctl -u modprobed-db.service | tail -20
```

## Workflow

1. **Install and Enable** (Day 1)
   - Import the kernel module in your NixOS configuration
   - Rebuild: `nh os switch`
   - The timer starts automatically

2. **Collect Module Data** (Weeks 1-4)
   - Use your system normally for daily tasks
   - Play games, use all hardware features
   - Connect USB devices, webcams, etc.
   - The service runs hourly in the background
   - Monitor progress: `modprobed-db list | wc -l`

3. **Enable Optimization** (After 2-4 weeks)
   - Uncomment the kernel optimization section
   - Set your CPU architecture (e.g., "znver4" for Ryzen 9000 series)
   - Rebuild: `nh os switch`
   - Warning: First build will take 30-60 minutes

4. **Maintain** (Ongoing)
   - Service continues tracking new modules
   - Rebuild kernel periodically to include new modules
   - Update `modprobed.db` before major kernel rebuilds

## Benefits

- **Faster Compilation**: Only build modules you actually use
- **Smaller Kernel**: Reduced kernel size and memory footprint
- **Optimized Performance**: CPU-specific optimizations
- **Security**: Smaller attack surface (fewer modules loaded)

## Using modprobed.db for Kernel Optimization

The database file at `/var/lib/modprobed-db/.config/modprobed-db/modprobed.db` contains a list of all kernel modules you've used. You can use this to:

1. Build a custom kernel with only these modules
2. Configure CachyOS kernel with optimized module selection
3. Reduce kernel compilation time significantly
4. Create a smaller, more secure kernel image

## Troubleshooting

### Module database is empty
```bash
# Check if service is running
systemctl status modprobed-db.timer

# Check for errors
sudo journalctl -u modprobed-db.service -n 50

# Manually run to test
sudo systemctl start modprobed-db.service
```

### Kernel build fails
- Make sure you've collected module data for at least 2 weeks
- Try building with `compiler = "gcc"` if using Clang
- Check if modprobed.db exists and isn't empty

### Missing hardware support after kernel optimization
- Boot the device/hardware you need
- Wait for hourly service to run or trigger manually
- Rebuild kernel: `nh os switch`

## Files

- Service config: `modules/kernel/modprobed-db.nix`
- Kernel optimization: `modules/kernel/default.nix`
- Module database: `/var/lib/modprobed-db/.config/modprobed-db/modprobed.db`
- Service logs: `journalctl -u modprobed-db.service`
