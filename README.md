# wait-and-pin-machine.sh


`wait-and-pin-machine.sh` is a helper script for **Proxmox VE** that automatically sets the **QEMU machine version** of a newly created VM to a compatible version (e.g. `pc-i440fx-9.2` or `q35-9.2`).

This is especially useful in **Veeam Backup & Restore** environments, since Veeam by default restores VMs with `machine: …-10.x`, which may cause compatibility issues.

---

### ✨ Features

- Waits (blocking) until `/etc/pve/qemu-server/<VMID>.conf` exists
- Normalizes an existing `machine:` line (e.g. `pc-i440fx-10.0` → `pc-i440fx-9.2`)
- Inserts a `machine:` line if it’s missing
- Auto-detects the chipset (`auto`), or allows forcing `i440fx` or `q35`
- Prints output to the terminal and logs to `/var/log/force-machine.log`
- Does **not** modify Proxmox core files — safe for clusters and the GUI

---

### 🛠️ Usage

Simply copy the script to the hypervisor you are restoring to and execute the loop:

```bash
wget https://raw.githubusercontent.com/fqfr/veeam-proxmox-workaround/refs/heads/main/wait-and-pin-machine.sh -O /usr/local/sbin/wait-and-pin-machine.sh
chmod +x /usr/local/sbin/wait-and-pin-machine.sh 

# Default: waits for VMID 102, auto-detects chipset, sets version to 9.2
wait-and-pin-machine.sh 102

# Force q35 chipset explicitly
wait-and-pin-machine.sh 102 q35 9.2

# Force i440fx chipset explicitly
wait-and-pin-machine.sh 102 i440fx 9.2
```

While the VM does not yet exist, the script prints a “waiting …” message every second.
Now start the veeam restore.
Once the config file appears, it is checked and modified if necessary. 

---

## 🧾 Example Output
```bash
2025-09-07T15:42:12+02:00 [vmid=102] waiting for /etc/pve/qemu-server/102.conf ...
2025-09-07T15:42:13+02:00 [vmid=102] waiting ...
2025-09-07T15:42:14+02:00 [vmid=102] found /etc/pve/qemu-server/102.conf
2025-09-07T15:42:15+02:00 [vmid=102] pinned to pc-i440fx-9.2
2025-09-07T15:42:15+02:00 [vmid=102] done.
```
---

## 📄 License

MIT License – see [LICENSE](LICENSE) file for details.
This script was created with the assistance of [ChatGPT (OpenAI, GPT-5)](https://openai.com/).
