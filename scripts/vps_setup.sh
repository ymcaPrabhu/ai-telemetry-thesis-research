#!/bin/bash

################################################################################
# VPS Setup Script for AI-Driven Multi-Source Telemetry Framework
# PhD Research by Prabhu Narayan (Roll No. 60222005)
# Supervisor: Dr. Mamta Mittal
# Institution: DSEU
################################################################################

set -e  # Exit on error

echo "================================================================================"
echo "VPS SETUP FOR AI-DRIVEN TELEMETRY FRAMEWORK"
echo "================================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_status "Starting VPS setup..."

# ============================================================================
# 1. SYSTEM UPDATE AND BASIC PACKAGES
# ============================================================================
echo ""
echo "Step 1: Updating system and installing basic packages..."
apt update && apt upgrade -y
apt install -y build-essential curl wget git vim nano htop tmux screen tree

print_status "System updated and basic packages installed"

# ============================================================================
# 2. PYTHON INSTALLATION
# ============================================================================
echo ""
echo "Step 2: Installing Python 3.10 and pip..."
apt install -y python3.10 python3.10-venv python3-pip
python3 --version
pip3 --version

print_status "Python 3.10 and pip installed"

# ============================================================================
# 3. DATABASE INSTALLATION (PostgreSQL)
# ============================================================================
echo ""
echo "Step 3: Installing PostgreSQL for experiment tracking..."
apt install -y postgresql postgresql-contrib

# Start PostgreSQL service
systemctl start postgresql
systemctl enable postgresql

print_status "PostgreSQL installed and started"

# ============================================================================
# 4. CREATE PROJECT STRUCTURE
# ============================================================================
echo ""
echo "Step 4: Creating project directory structure..."

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$ACTUAL_USER)
PROJECT_DIR="$USER_HOME/ai-telemetry-research"

mkdir -p "$PROJECT_DIR"/{datasets,notebooks,results,models,logs,scripts,configs}
mkdir -p "$PROJECT_DIR"/datasets/{raw,processed,synthetic}
mkdir -p "$PROJECT_DIR"/results/{phase1,phase2,phase3,phase4,phase5}
mkdir -p "$PROJECT_DIR"/models/{baseline_ml,deep_learning,optimized,fusion}
mkdir -p "$PROJECT_DIR"/logs/{training_logs,experiment_tracking}

# Set ownership to actual user
chown -R $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR"

print_status "Project directory structure created at $PROJECT_DIR"

# ============================================================================
# 5. PYTHON VIRTUAL ENVIRONMENT
# ============================================================================
echo ""
echo "Step 5: Creating Python virtual environment..."

cd "$PROJECT_DIR"
sudo -u $ACTUAL_USER python3 -m venv venv

print_status "Virtual environment created"

# ============================================================================
# 6. INSTALL PYTHON DEPENDENCIES
# ============================================================================
echo ""
echo "Step 6: Installing Python dependencies..."

# Create requirements.txt
cat > "$PROJECT_DIR/requirements.txt" << 'EOF'
# Core Data Science
numpy==1.24.3
pandas==2.0.3
scipy==1.11.1

# Machine Learning
scikit-learn==1.3.0
xgboost==1.7.6
lightgbm==4.0.0
catboost==1.2

# Deep Learning
tensorflow==2.13.0
torch==2.0.1
torchvision==0.15.2

# Explainable AI
shap==0.42.1
lime==0.2.0.1

# Visualization
matplotlib==3.7.2
seaborn==0.12.2
plotly==5.15.0

# Utilities
tqdm==4.65.0
joblib==1.3.1
python-dotenv==1.0.0

# Data Processing
pyarrow==12.0.1
fastparquet==2023.7.0

# Experiment Tracking
mlflow==2.5.0
wandb==0.15.7

# Cloud Integration
boto3==1.28.17
google-cloud-storage==2.10.0
azure-storage-blob==12.17.0

# SSH and File Transfer
paramiko==3.2.0
scp==0.14.5

# Database
psycopg2-binary==2.9.7
sqlalchemy==2.0.19

# Jupyter
jupyter==1.0.0
jupyterlab==4.0.3
ipywidgets==8.0.7
EOF

# Install dependencies
sudo -u $ACTUAL_USER "$PROJECT_DIR/venv/bin/pip" install --upgrade pip
sudo -u $ACTUAL_USER "$PROJECT_DIR/venv/bin/pip" install -r "$PROJECT_DIR/requirements.txt"

print_status "Python dependencies installed"

# ============================================================================
# 7. CREATE EXPERIMENT TRACKING DATABASE
# ============================================================================
echo ""
echo "Step 7: Setting up experiment tracking database..."

sudo -u postgres psql -c "CREATE DATABASE telemetry_experiments;" || print_warning "Database may already exist"
sudo -u postgres psql -c "CREATE USER telemetry_user WITH PASSWORD 'secure_password';" || print_warning "User may already exist"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE telemetry_experiments TO telemetry_user;"

# Create database schema
sudo -u $ACTUAL_USER "$PROJECT_DIR/venv/bin/python" << 'PYTHON_EOF'
import psycopg2
from psycopg2 import sql

try:
    conn = psycopg2.connect(
        dbname="telemetry_experiments",
        user="telemetry_user",
        password="secure_password",
        host="localhost"
    )
    cur = conn.cursor()

    # Create experiments table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS experiments (
            exp_id SERIAL PRIMARY KEY,
            experiment_name TEXT NOT NULL,
            phase TEXT,
            notebook_name TEXT,
            dataset TEXT,
            model_type TEXT,
            start_time TIMESTAMP,
            end_time TIMESTAMP,
            status TEXT,
            notes TEXT
        );
    """)

    # Create metrics table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS metrics (
            metric_id SERIAL PRIMARY KEY,
            exp_id INTEGER REFERENCES experiments(exp_id),
            metric_name TEXT,
            metric_value REAL
        );
    """)

    # Create artifacts table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS artifacts (
            artifact_id SERIAL PRIMARY KEY,
            exp_id INTEGER REFERENCES experiments(exp_id),
            artifact_type TEXT,
            file_path TEXT,
            file_size INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)

    conn.commit()
    cur.close()
    conn.close()
    print("Database schema created successfully")
except Exception as e:
    print(f"Database setup error (may be normal if already exists): {e}")
PYTHON_EOF

print_status "Experiment tracking database configured"

# ============================================================================
# 8. CREATE BACKUP SCRIPT
# ============================================================================
echo ""
echo "Step 8: Creating automated backup script..."

cat > "$PROJECT_DIR/scripts/backup.sh" << 'EOF'
#!/bin/bash
# Automated backup script for research data

BACKUP_DIR="$HOME/backups"
RESEARCH_DIR="$HOME/ai-telemetry-research"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Create compressed backup
tar -czf "$BACKUP_DIR/research_backup_$DATE.tar.gz" \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    "$RESEARCH_DIR"

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "research_backup_*.tar.gz" -mtime +30 -delete

echo "Backup completed: research_backup_$DATE.tar.gz"
EOF

chmod +x "$PROJECT_DIR/scripts/backup.sh"
chown $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR/scripts/backup.sh"

# Add to crontab (daily at 2 AM)
(crontab -u $ACTUAL_USER -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/scripts/backup.sh") | crontab -u $ACTUAL_USER -

print_status "Backup script created and scheduled (daily at 2 AM)"

# ============================================================================
# 9. CREATE HELPER SCRIPTS
# ============================================================================
echo ""
echo "Step 9: Creating helper scripts..."

# Data sync script
cat > "$PROJECT_DIR/scripts/sync_from_colab.sh" << 'EOF'
#!/bin/bash
# Sync results from Google Colab/Drive to VPS

SOURCE_DIR="/path/to/google/drive/ai-telemetry-research"
DEST_DIR="$HOME/ai-telemetry-research"

# Example using rclone (install with: curl https://rclone.org/install.sh | sudo bash)
# rclone sync gdrive:ai-telemetry-research $DEST_DIR

echo "Configure this script with your Google Drive sync method"
echo "Options: rclone, rsync via SSH, manual download"
EOF

chmod +x "$PROJECT_DIR/scripts/sync_from_colab.sh"
chown $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR/scripts/sync_from_colab.sh"

print_status "Helper scripts created"

# ============================================================================
# 10. FIREWALL CONFIGURATION
# ============================================================================
echo ""
echo "Step 10: Configuring firewall..."

apt install -y ufw
ufw --force enable
ufw allow ssh
ufw allow 22/tcp
ufw status

print_status "Firewall configured"

# ============================================================================
# 11. CREATE ENVIRONMENT FILE
# ============================================================================
echo ""
echo "Step 11: Creating environment configuration file..."

cat > "$PROJECT_DIR/.env" << EOF
# VPS Environment Configuration
PROJECT_DIR=$PROJECT_DIR
DB_HOST=localhost
DB_PORT=5432
DB_NAME=telemetry_experiments
DB_USER=telemetry_user
DB_PASSWORD=secure_password

# Google Drive sync (configure as needed)
GDRIVE_SYNC_PATH=/path/to/gdrive

# Backup settings
BACKUP_RETENTION_DAYS=30
EOF

chown $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR/.env"
chmod 600 "$PROJECT_DIR/.env"

print_status "Environment file created"

# ============================================================================
# 12. SYSTEM MONITORING SETUP
# ============================================================================
echo ""
echo "Step 12: Setting up system monitoring..."

apt install -y prometheus-node-exporter

# Create monitoring script
cat > "$PROJECT_DIR/scripts/monitor.sh" << 'EOF'
#!/bin/bash
# System monitoring script

echo "=== System Status ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print "  "$2" user, "$4" system, "$8" idle"}'

echo ""
echo "Memory Usage:"
free -h | grep "Mem:" | awk '{print "  Used: "$3" / Total: "$2" ("$3/$2*100"%)"}'

echo ""
echo "Disk Usage:"
df -h / | tail -1 | awk '{print "  Used: "$3" / Total: "$2" ("$5")"}'

echo ""
echo "GPU Status:"
nvidia-smi 2>/dev/null || echo "  No GPU detected"

echo ""
echo "Running Processes:"
ps aux | grep python | grep -v grep | wc -l | awk '{print "  Active Python processes: "$1}'
EOF

chmod +x "$PROJECT_DIR/scripts/monitor.sh"
chown $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR/scripts/monitor.sh"

print_status "System monitoring configured"

# ============================================================================
# 13. CREATE ACTIVATION SCRIPT
# ============================================================================
echo ""
echo "Step 13: Creating quick activation script..."

cat > "$PROJECT_DIR/activate_env.sh" << EOF
#!/bin/bash
# Quick activation script for research environment

source $PROJECT_DIR/venv/bin/activate
cd $PROJECT_DIR

echo "================================"
echo "Research Environment Activated"
echo "================================"
echo "Project: AI-Driven Multi-Source Telemetry Framework"
echo "Location: $PROJECT_DIR"
echo ""
echo "Quick commands:"
echo "  - Run backup: ./scripts/backup.sh"
echo "  - Monitor system: ./scripts/monitor.sh"
echo "  - Sync from Colab: ./scripts/sync_from_colab.sh"
echo ""
PS1="(telemetry-research) \u@\h:\w$ "
EOF

chmod +x "$PROJECT_DIR/activate_env.sh"
chown $ACTUAL_USER:$ACTUAL_USER "$PROJECT_DIR/activate_env.sh"

print_status "Activation script created"

# ============================================================================
# FINAL SUMMARY
# ============================================================================
echo ""
echo "================================================================================"
echo " VPS SETUP COMPLETED SUCCESSFULLY!"
echo "================================================================================"
echo ""
echo "Project Location: $PROJECT_DIR"
echo "Python Version: $(python3 --version)"
echo "Virtual Environment: $PROJECT_DIR/venv"
echo ""
echo "NEXT STEPS:"
echo "1. Switch to user account: su - $ACTUAL_USER"
echo "2. Activate environment: source $PROJECT_DIR/activate_env.sh"
echo "3. Configure Google Drive sync in scripts/sync_from_colab.sh"
echo "4. Upload Colab notebooks to $PROJECT_DIR/notebooks/"
echo "5. Start running experiments!"
echo ""
echo "IMPORTANT FILES:"
echo "  - Environment config: $PROJECT_DIR/.env"
echo "  - Backup script: $PROJECT_DIR/scripts/backup.sh (runs daily at 2 AM)"
echo "  - Monitor script: $PROJECT_DIR/scripts/monitor.sh"
echo ""
echo "DATABASE ACCESS:"
echo "  psql -U telemetry_user -d telemetry_experiments"
echo ""
echo "================================================================================"
