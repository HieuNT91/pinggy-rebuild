# Pinggy rebuild for the fresh Ubuntu installation

These files are templates, not installed or activated. End-to-end connectivity
must be tested on the target server. Review them before deployment and generate
fresh keys and tokens on trusted devices.

## Install from the fresh server's local console

First create the `hieunt` account and install a newly generated laptop public
key in its ~/.ssh/authorized_keys (directory 0700, file 0600, owned by hieunt).
Keep the private key only on the laptop. If your username differs, change
AllowUsers in 00-key-only.conf before installing it.

Run the following from this bundle's directory, on the fresh server only:

```bash
sudo apt update
sudo apt install openssh-server openssh-client
sudo useradd --system --user-group --home-dir /var/lib/pinggy-tunnel --shell /usr/sbin/nologin pinggy-tunnel
sudo install -d -o pinggy-tunnel -g pinggy-tunnel -m 0700 /var/lib/pinggy-tunnel
sudo -u pinggy-tunnel ssh-keygen -t ed25519 -N '' -f /var/lib/pinggy-tunnel/relay_ed25519
sudo install -d -o root -g pinggy-tunnel -m 0750 /etc/pinggy-tunnel
sudo install -o root -g pinggy-tunnel -m 0640 ssh_config /etc/pinggy-tunnel/ssh_config
sudo install -o root -g root -m 0644 pinggy-tunnel.service /etc/systemd/system/pinggy-tunnel.service
sudo install -o root -g root -m 0644 00-key-only.conf /etc/ssh/sshd_config.d/00-key-only.conf
sudo sshd -t
sudo sshd -T -C user=hieunt,host=localhost,addr=127.0.0.1 | grep -E '^(authenticationmethods|passwordauthentication|kbdinteractiveauthentication|permitrootlogin|allowusers|pubkeyauthentication) '
```

Stop if validation fails or effective settings do not match the supplied
key-only configuration. Check for conflicting configuration and Match blocks.
Then reload SSH and test a separate laptop key login over the LAN while
keeping the local console available:

```bash
sudo systemctl reload ssh
```

## Verify the relay host key before activating forwarding

The default uses Pinggy's free TCP relay. For Pro, edit HostName to
pro.pinggy.io and User to NEW_TOKEN+tcp in the root-owned ssh_config.
Rotate any previously used token. Do not paste tokens into chat.

Obtain the relay host key and verify its fingerprint independently with
Pinggy/support or a previously trusted record on a clean device. ssh-keyscan
alone does NOT authenticate the key. After verification, put the matching
known_hosts entry for [free.pinggy.io]:443 (or [pro.pinggy.io]:443) in a local
file named verified-relay-known-hosts. Then:

```bash
sudo install -o root -g pinggy-tunnel -m 0640 verified-relay-known-hosts /etc/pinggy-tunnel/known_hosts
sudo systemctl daemon-reload
sudo systemctl enable --now pinggy-tunnel.service
sudo journalctl -u pinggy-tunnel.service -n 50 --no-pager
```

StrictHostKeyChecking=yes deliberately refuses unknown/changed relay keys.
The separate relay key is not a server-login credential; never add it to
hieunt's authorized_keys. No SSH agent forwarding is enabled.

Pinggy prints its public address/port in the service log. Free addresses can
change after reconnection. Pro supports persistent endpoints. Connect from
the laptop with `ssh -p PUBLIC_PORT hieunt@PUBLIC_HOST` and verify the NEW
server host key against its fingerprint at the server console:

```bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Test that the right key works and an unrelated key/password-only login fails.
After a reboot, verify Wi-Fi reconnects, the tunnel is active, and laptop SSH
still works. End-to-end connectivity has not been tested in this preparation.

Do not bring back the old start_pinggy.service. Keep SSH available only to
intended networks/devices where feasible. Do not blanket-block loopback SSH:
the tunnel needs it. Tunneled SSH commonly logs the relay connection as
127.0.0.1; IP-based fail2ban can block every tunneled user together. Prefer
key authentication and Pinggy-side IP restrictions if your client IP is stable.
HTTP tunnel authentication options do not protect a raw TCP SSH tunnel.

Keep Ubuntu patched; send authentication logs to a separate trusted host.
Only administrators need sudo. Docker/LXD management membership can also
confer root-equivalent privileges. Never reuse shared account passwords.

Provider reference: https://pinggy.io/docs/guides/ssh_linux/
