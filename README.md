# Anti-DDoS Tool (antiddos) v2.0.0

`antiddos` is a high-performance, visually enhanced bash tool designed to protect Linux servers from Distributed Denial of Service (DDoS) attacks. It provides a clean CLI interface to manage complex `iptables` rules.

## ✨ Premium Features

- **🚀 Advanced Protection**:
  - SYN, UDP, and ICMP Flood mitigation.
  - Port scan detection and prevention.
  - Invalid packet and fragmentation filtering.
- **🖥️ Monitoring Dashboard**:
  - Real-time view of dropped packets and server connections.
- **🛠️ Management Tools**:
  - **Whitelisting/Blacklisting**: Easily manage trusted and blocked IPs.
  - **Persistence**: Save rules to apply automatically on system reboot.
- **🎨 Modern CLI**:
  - Stylish ASCII banner and colored feedback with clear icons.

## 🚀 Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/ismailtsdln/antiddos.git
   cd antiddos
   ```

2. Make the script executable:

   ```bash
   chmod +x antiddos.sh
   ```

## 📖 Usage

Run with root privileges:

| Command | Description |
| :--- | :--- |
| `sudo ./antiddos.sh start` | Apply all Anti-DDoS protection rules |
| `sudo ./antiddos.sh stop` | Remove all rules and revert to defaults |
| `sudo ./antiddos.sh status` | View current protection and rule status |
| `sudo ./antiddos.sh monitor` | Launch real-time monitoring dashboard |
| `sudo ./antiddos.sh whitelist <IP>` | Add an IP address to the whitelist |
| `sudo ./antiddos.sh blacklist <IP>` | Block a specific IP address |
| `sudo ./antiddos.sh save` | Make current rules persistent across reboots |
| `sudo ./antiddos.sh clear` | Flush all iptables rules |

## ⚠️ Requirements

- `iptables` (Core firewall)
- `iptables-persistent` (Optional, required for `save` command)
- `ss` or `netstat` (For monitoring dashboard)

## ⚖️ License

MIT License. Designed with ❤️ for server security.
