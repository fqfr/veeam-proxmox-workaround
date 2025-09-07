cat >/usr/local/sbin/wait-and-pin-machine.sh <<'EOF'
#!/bin/bash
# Usage: wait-and-pin-machine.sh <VMID> [q35|i440fx] [VERSION]
# Default: chipset auto, VERSION 9.2
# Credits: https://github.com/fqfr/veeam-proxmox-workaround
VMID="$1"
PREF_CHIPSET="${2:-auto}"   # auto|q35|i440fx
TARGET_VER="${3:-9.2}"

CONF_DIR="/etc/pve/qemu-server"
CONF_PATH="${CONF_DIR}/${VMID}.conf"
LOG="/var/log/force-machine.log"

echo "$(date -Is) [vmid=$VMID] waiting for $CONF_PATH ..."
# Warten bis Datei existiert – sichtbar und endlos
while true; do
  if [ -f "$CONF_PATH" ]; then
    echo "$(date -Is) [vmid=$VMID] found $CONF_PATH"
    break
  fi
  echo "$(date -Is) [vmid=$VMID] waiting ..."
  sleep 1
done

# kurze Stabilitätspause
sleep 1

# Chipset bestimmen
chipset="pc-i440fx"
case "$PREF_CHIPSET" in
  q35)    chipset="q35" ;;
  i440fx) chipset="pc-i440fx" ;;
  auto)
    grep -qE '^(hostpci|pcie|machine:\s*q35)' "$CONF_PATH" && chipset="q35"
    ;;
esac

tmp="$(mktemp -p "$CONF_DIR" .${VMID}.XXXXXX 2>/dev/null || mktemp)"
if grep -qE '^\s*machine:\s*(pc-i440fx|q35)-[0-9]+\.[0-9]+' "$CONF_PATH"; then
  # vorhandene Version (auch 10.x) -> 9.2 umschreiben (Suffixe wie +pve0 bleiben)
  sed -E 's/^(machine:\s*(pc-i440fx|q35))-[0-9]+\.[0-9]+/\1-'"${TARGET_VER}"'/' "$CONF_PATH" > "$tmp"
else
  # keine machine-Zeile -> einfügen (oben)
  { echo "machine: ${chipset}-${TARGET_VER}"; cat "$CONF_PATH"; } > "$tmp"
fi

if ! cmp -s "$CONF_PATH" "$tmp"; then
  chown --reference="$CONF_PATH" "$tmp" 2>/dev/null || true
  chmod --reference="$CONF_PATH" "$tmp" 2>/dev/null || true
  mv -f "$tmp" "$CONF_PATH"
  echo "$(date -Is) [vmid=$VMID] pinned to ${chipset}-${TARGET_VER}" | tee -a "$LOG"
else
  rm -f "$tmp"
  echo "$(date -Is) [vmid=$VMID] no change needed" | tee -a "$LOG"
fi

echo "$(date -Is) [vmid=$VMID] done."
EOF

chmod +x /usr/local/sbin/wait-and-pin-machine.sh
