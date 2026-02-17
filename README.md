# 🚀 PAQET Tunnel Manager

<p align="center">
  <img src="https://img.shields.io/badge/Version-10.7-blueviolet.svg" alt="Version">
  <img src="https://img.shields.io/badge/Platform-Linux-orange.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

<p align="center">
  <b>Professional KCP Tunnel Deployment & Management Script</b><br>
  Designed for high-performance, stability, and automation.
</p>

---

## 📌 Overview

**PAQET Tunnel Manager** is a professional all-in-one automation tool for deploying and managing high-performance **KCP tunnels** using the Paqet core.

It simplifies complex networking configurations into a clean, interactive terminal interface — making tunnel deployment fast, reliable, and optimized for production environments.

---

## ✨ Key Features

- ⚡ **One-Click Installation**  
  Automatically installs all dependencies, Paqet core, and required management tools.

- 🛠 **Automated Configuration**  
  Generates optimized YAML configuration files for:
  - KHAREJ (Server)
  - IRAN (Client)

- 🌍 **Smart Port Forwarding**  
  Supports multiple forwarding rules with seamless routing.

- 🚀 **Network Optimization**  
  Built-in support for:
  - TCP BBR
  - TCP Hybla  
  Reduces latency and improves throughput.

- ⏰ **High Availability System**  
  Integrated cronjob automation for service auto-restart and uptime stability.

- 💻 **Global Command Access**  
  Access the manager anytime using:
  ```bash
  HEX_PAQET
  ```

---

## 📥 Installation

Run the following command on your server:

```bash
curl -sSL https://raw.githubusercontent.com/hexmostafa/paqet-manager/main/install.sh | bash
```

> ⚠ If your repository name or GitHub username is different, replace `hexmostafa/paqet-manager` accordingly.

---

## 🚀 Usage

After installation, simply run:

```bash
HEX_PAQET
```

You will see the interactive management menu.

---

## 📋 Menu Overview

| Option | Description |
|--------|------------|
| Install Core | Install or update the Paqet binary |
| New KHAREJ | Configure server-side tunnel |
| New IRAN | Configure client-side tunnel with forwarding |
| List Tunnels | Monitor active/inactive tunnels |
| Cronjob | Schedule automatic service restarts |
| Network Optimization | Enable BBR or Hybla congestion control |

---

## 🛡 Requirements

- **Operating System:** Ubuntu 20.04+ or Debian 11+ (Recommended)
- **Privileges:** Root access or sudo user
- **Architecture:** x86_64

---

## 📂 Project Structure

```
hexmostafa/
├── paqet-manager.sh
├── paqet
├── configs/
└── logs/
```

---

## 🤝 Contributing

Contributions, suggestions, issues, and feature requests are welcome.

If you’d like to improve this project:

1. Fork the repository  
2. Create your feature branch  
3. Commit your changes  
4. Open a Pull Request  

---

## 📜 License

This project is licensed under the **MIT License**.

---

<p align="center">
  Made with ❤️ by <b>HEXMOSTAFA</b>
</p>
