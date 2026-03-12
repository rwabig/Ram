Step 1: Check if Swap Already Exists
Run:

swapon --show
If there is no output, your server has no swap.

Check system memory:

free -h
You’ll see something like:

Swap:       0B        0B        0B
If swap exists, you’ll see numbers like:

Swap:     1.0G      50M     950M
Step 2: Create Swap File (Recommended Method)
Most VPS users should create swap using a swapfile — not partition.

Create a 2GB swap file:

fallocate -l 2G /swapfile
If fallocate doesn’t work (rare), use:

dd if=/dev/zero of=/swapfile bs=1M count=2048
Secure the swap file:

chmod 600 /swapfile
Turn swapfile into usable swap:

mkswap /swapfile
Enable swap:

swapon /swapfile
Verify:

swapon --show
free -h
You now have swap memory active.

Step 3: Make Swap Permanent
Add to /etc/fstab:

echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
This ensures swap loads on reboot.

Step 4: Choose the Right Swap Size
A basic rule:

RAM	Recommended Swap
1 GB	1–2 GB
2 GB	1 GB
4 GB	1 GB or none
8 GB+	Swap optional
For VPS servers running:

WordPress

Virtualmin

MariaDB

Composer/Docker tasks

2 GB is the sweet spot.

Step 5: Increase Swap Size (If You Already Have Swap)
If swap is too small, remove the old file and recreate a bigger one.

Disable current swap:

swapoff -a
Create larger file (example: 4GB):

fallocate -l 4G /swapfile
Secure & re-enable:

chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
Update fstab (if needed):

nano /etc/fstab
Ensure line exists:

/swapfile none swap sw 0 0
Step 6: Optimize Swap (Optional but Recommended)
1. Adjust swappiness

Controls how often Ubuntu uses swap.

Check current value:

cat /proc/sys/vm/swappiness
Default is often 60 (too aggressive).

Set to 10:

echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf
sudo sysctl -p
2. Adjust cache pressure

Improves filesystem caching:

echo 'vm.vfs_cache_pressure=50' | sudo tee /etc/sysctl.d/99-cache-pressure.conf
sudo sysctl -p
Step 7: Verify Everything Works
Run:

free -h
swapon --show
You should see swap activated.

Reboot test:

reboot
After reboot:

swapon --show
If it shows your swapfile → your setup is successful.

When Should You NOT Use Swap?
Avoid swap if:

Your VPS uses slow HDD storage

Your workload is high-performance (DB-heavy)

You rely on predictable latency

For typical WordPress + Nginx + PHP-FPM + Virtualmin servers, swap is safe and recommended.

🎯 Conclusion
