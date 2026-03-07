# 🛠️ Infrastructure Scripts

[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**55 production-ready automation scripts for infrastructure monitoring, deployment, backup, and security.**

## 📁 Categories

### 🔍 Monitoring & Health
| Script | Description |
|--------|-------------|
| ot-watchdog.sh | Monitor and auto-restart services |
| check-automation.sh | Verify automation jobs are running |
| check-deploy.sh | Deployment verification |
| check-security-alerts.sh | Security alert monitoring |
| enhanced-monitor.sh | Advanced system monitoring |
| proactive-monitor.sh | Proactive issue detection |

### 💾 Backup & Recovery  
| Script | Description |
|--------|-------------|
| ackup.sh | System backup automation |
| ackup-to-mac-pro.sh | Cross-machine backup |
| quick-restore.sh | Fast restore from backup |
| estore.sh | Full system restore |
| unified-backup.sh | Unified backup strategy |

### 📊 Reporting & Logging
| Script | Description |
|--------|-------------|
| daily-status-report.sh | Daily system status |
| cost-report.sh | Infrastructure cost tracking |
| cost-tracker.sh | LLM API cost tracking |
| weekly-summary.sh | Weekly summary reports |
| ggregate-logs.sh | Log aggregation |
| udit-log.sh | Audit trail logging |
| udit-report.sh | Compliance reporting |

### 🚀 Deployment
| Script | Description |
|--------|-------------|
| deploy.sh | Main deployment script |
| post-deploy.sh | Post-deployment checks |
| update-dashboard.sh | Dashboard deployment |
| swarm-deployment-heartbeat.sh | Swarm health check |

### 🔒 Security
| Script | Description |
|--------|-------------|
| security-alert.sh | Security alerting |
| security-audit-cron.sh | Scheduled security audits |
| security-audit-notify.sh | Security notifications |
| security-audit.sh | Manual security audit |
| security-monitor.sh | Real-time security monitoring |
| ort-knox-policy.sh | Security policy enforcement |

### 🔄 Automation
| Script | Description |
|--------|-------------|
| uto-commit-memory.sh | Auto-commit changes |
| uto-email-check.sh | Email monitoring |
| uto-financial-monitor.sh | Financial data monitoring |
| sync-knowledge.sh | Knowledge base sync |
| sync-shared-brain.sh | Cross-node sync |

## 🚀 Usage

`ash
# Make executable
chmod +x script-name.sh

# Run directly
./script-name.sh

# Schedule via cron
0 * * * * /path/to/script-name.sh
`

## 📋 Requirements

- Bash 4.0+
- curl, jq (for API scripts)
- ssh (for remote scripts)

## 👨‍💻 Author

**Tommie Seals** - Infrastructure & Platform Engineer

---

*Part of the infrastructure automation portfolio.*
