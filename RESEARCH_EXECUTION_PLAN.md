# AI-Driven Multi-Source Telemetry Framework - Complete Execution Plan
## PhD Research by Prabhu Narayan (Roll No. 60222005)

---

## 📋 Table of Contents
1. [Overview](#overview)
2. [Research Architecture](#research-architecture)
3. [VPS Setup Guide](#vps-setup-guide)
4. [Google Colab Integration](#google-colab-integration)
5. [Experimental Workflow](#experimental-workflow)
6. [Data Management Strategy](#data-management-strategy)
7. [Execution Timeline](#execution-timeline)
8. [Results Storage Structure](#results-storage-structure)

---

## 1. Overview

### Research Objectives
This execution plan implements the **AI-Driven Multi-Source Telemetry Framework for Cyberattack Detection in Cloud Environments** across 5 research phases:

- **Phase I**: Data acquisition and preprocessing
- **Phase II**: Baseline ML models (Random Forest, SVM, Gradient Boosting)
- **Phase III**: Advanced DL models (CNN, LSTM, Transformers) + XAI
- **Phase IV**: Multi-cloud validation and optimization
- **Phase V**: Results compilation and analysis

### Technology Stack
- **Development**: Google Colab (GPU/TPU for training)
- **Storage**: VPS (Virtual Private Server)
- **Datasets**: CICIDS2017, UNSW-NB15, BoT-IoT, CTU-13, Synthetic Cloud Data
- **Frameworks**: TensorFlow, PyTorch, Scikit-learn, XGBoost
- **XAI Tools**: SHAP, LIME
- **Data Pipeline**: Apache Kafka (simulated), Spark, Pandas

---

## 2. Research Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                      Google Colab (Compute Layer)               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Data Prep    │  │ ML/DL Models │  │ XAI Analysis │          │
│  │ Notebooks    │  │ Training     │  │ & Evaluation │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              ↕ SSH/SFTP/Google Drive API
┌─────────────────────────────────────────────────────────────────┐
│                    VPS (Storage & Orchestration)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Raw Datasets │  │ Preprocessed │  │ Model Results│          │
│  │ Storage      │  │ Features     │  │ & Metrics    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │ Experiment Tracking Database (SQLite/PostgreSQL) │          │
│  └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Source Telemetry Integration

```
Network Telemetry    System Logs       IAM Logs         Application Logs
     (NetFlow)      (Process/File)   (Auth/Privs)         (API/HTTP)
        │                │                │                    │
        └────────────────┴────────────────┴────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Feature Fusion   │
                    │   Engine          │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  AI/ML/DL Models  │
                    │  (CNN/LSTM/RF)    │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │   XAI Layer       │
                    │  (SHAP/LIME)      │
                    └───────────────────┘
```

---

## 3. VPS Setup Guide

### 3.1 Initial VPS Configuration

**Minimum Requirements:**
- OS: Ubuntu 20.04/22.04 LTS
- RAM: 16GB minimum (32GB recommended)
- Storage: 500GB SSD
- CPU: 8+ cores
- Network: 100Mbps+

### 3.2 Installation Steps

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and dependencies
sudo apt install -y python3.10 python3-pip python3-venv git wget curl

# Install system utilities
sudo apt install -y htop tmux screen vim nano tree

# Install database (PostgreSQL for experiment tracking)
sudo apt install -y postgresql postgresql-contrib

# Install monitoring tools
sudo apt install -y prometheus-node-exporter
```

### 3.3 Create Project Structure

```bash
# Create main research directory
mkdir -p ~/ai-telemetry-research
cd ~/ai-telemetry-research

# Create subdirectories
mkdir -p {datasets,notebooks,results,models,logs,scripts,configs}
mkdir -p datasets/{raw,processed,synthetic}
mkdir -p results/{phase1,phase2,phase3,phase4,phase5}
mkdir -p models/{baseline_ml,deep_learning,optimized}
```

### 3.4 Python Environment Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install core dependencies
pip install --upgrade pip
pip install jupyter jupyterlab numpy pandas scikit-learn
pip install tensorflow torch torchvision
pip install xgboost lightgbm catboost
pip install shap lime
pip install matplotlib seaborn plotly
pip install mlflow wandb
pip install paramiko scp google-colab-ssh
```

---

## 4. Google Colab Integration

### 4.1 Connection Method 1: Google Drive Mounting (Recommended)

**Advantages:**
- Simple setup
- Persistent storage
- Easy file sharing

**Implementation:**
```python
# In Colab notebook
from google.colab import drive
drive.mount('/content/drive')

# Set working directory
import os
os.chdir('/content/drive/MyDrive/ai-telemetry-research')
```

### 4.2 Connection Method 2: Direct VPS SSH

**Setup on VPS:**
```bash
# Install ngrok for reverse tunnel (optional)
wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux-amd64.zip
sudo mv ngrok /usr/local/bin/

# Configure SSH
sudo nano /etc/ssh/sshd_config
# Ensure: PermitRootLogin no, PasswordAuthentication yes (or use keys)
sudo systemctl restart ssh
```

**In Colab:**
```python
# Install colab-ssh
!pip install colab-ssh

from colab_ssh import launch_ssh_cloudflared, init_git_cloudflared
launch_ssh_cloudflared(password="your_secure_password")
```

### 4.3 Connection Method 3: Rsync/SCP for Data Transfer

**VPS Script (upload_to_vps.py):**
```python
import paramiko
import os

def upload_results(local_path, remote_path, host, username, password):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=username, password=password)

    sftp = ssh.open_sftp()
    sftp.put(local_path, remote_path)
    sftp.close()
    ssh.close()
```

---

## 5. Experimental Workflow

### 5.1 Phase-wise Execution

#### **Phase I: Data Preparation (Months 1-6)**

**Notebooks:**
1. `01_dataset_download_preparation.ipynb`
2. `02_data_exploration_analysis.ipynb`
3. `03_feature_engineering_telemetry.ipynb`
4. `04_data_augmentation_synthetic.ipynb`

**Execution:**
```bash
# On VPS: Download datasets
cd ~/ai-telemetry-research/datasets/raw
wget https://www.unb.ca/cic/datasets/ids-2017.html  # CICIDS2017
wget https://research.unsw.edu.au/projects/unsw-nb15-dataset  # UNSW-NB15
# ... download other datasets

# Run notebooks on Colab (upload to Drive)
# Results saved to: results/phase1/
```

#### **Phase II: Baseline ML Models (Months 7-12)**

**Notebooks:**
1. `05_baseline_random_forest.ipynb`
2. `06_baseline_svm_gradient_boosting.ipynb`
3. `07_ensemble_models.ipynb`
4. `08_cross_validation_metrics.ipynb`

**Expected Outputs:**
- Model accuracy: ~95-97%
- Trained models saved to: `models/baseline_ml/`
- Performance metrics: `results/phase2/baseline_metrics.csv`

#### **Phase III: Advanced DL + XAI (Months 13-18)**

**Notebooks:**
1. `09_cnn_architecture_training.ipynb`
2. `10_lstm_temporal_detection.ipynb`
3. `11_transformer_attention_models.ipynb`
4. `12_xai_shap_lime_integration.ipynb`
5. `13_multi_source_fusion.ipynb`

**Expected Outputs:**
- CNN/LSTM accuracy: ~98-99%
- XAI visualizations
- Feature importance rankings

#### **Phase IV: Multi-Cloud Validation (Months 19-24)**

**Notebooks:**
1. `14_model_optimization_pruning.ipynb`
2. `15_multi_cloud_deployment_test.ipynb`
3. `16_attack_simulation_validation.ipynb`

#### **Phase V: Results & Thesis (Months 25-30)**

**Notebooks:**
1. `17_comprehensive_evaluation.ipynb`
2. `18_comparative_analysis.ipynb`
3. `19_publication_visualizations.ipynb`

---

## 6. Data Management Strategy

### 6.1 Storage Structure on VPS

```
~/ai-telemetry-research/
├── datasets/
│   ├── raw/
│   │   ├── CICIDS2017/
│   │   ├── UNSW-NB15/
│   │   ├── BoT-IoT/
│   │   └── CTU-13/
│   ├── processed/
│   │   ├── cicids_features.csv
│   │   ├── unsw_features.csv
│   │   └── combined_telemetry.parquet
│   └── synthetic/
│       └── cloud_attack_sim.csv
├── results/
│   ├── phase1/
│   │   ├── eda_reports/
│   │   └── preprocessing_stats.json
│   ├── phase2/
│   │   ├── baseline_metrics.csv
│   │   ├── confusion_matrices/
│   │   └── model_comparisons.png
│   ├── phase3/
│   │   ├── dl_model_metrics.csv
│   │   ├── xai_visualizations/
│   │   └── fusion_results.json
│   ├── phase4/
│   │   └── deployment_tests/
│   └── phase5/
│       └── final_thesis_data/
├── models/
│   ├── baseline_ml/
│   │   ├── random_forest_v1.pkl
│   │   └── xgboost_v1.pkl
│   ├── deep_learning/
│   │   ├── cnn_best.h5
│   │   ├── lstm_best.pth
│   │   └── transformer_best.pth
│   └── optimized/
│       └── pruned_models/
├── logs/
│   ├── training_logs/
│   └── experiment_tracking.db
└── notebooks/
    └── (all .ipynb files synced from Colab)
```

### 6.2 Experiment Tracking Database Schema

**SQLite Database: `experiment_tracking.db`**

```sql
CREATE TABLE experiments (
    exp_id INTEGER PRIMARY KEY AUTOINCREMENT,
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

CREATE TABLE metrics (
    metric_id INTEGER PRIMARY KEY AUTOINCREMENT,
    exp_id INTEGER,
    metric_name TEXT,
    metric_value REAL,
    FOREIGN KEY (exp_id) REFERENCES experiments(exp_id)
);

CREATE TABLE artifacts (
    artifact_id INTEGER PRIMARY KEY AUTOINCREMENT,
    exp_id INTEGER,
    artifact_type TEXT,
    file_path TEXT,
    file_size INTEGER,
    created_at TIMESTAMP,
    FOREIGN KEY (exp_id) REFERENCES experiments(exp_id)
);
```

---

## 7. Execution Timeline

### Monthly Breakdown

**Months 1-2: Setup & Data Acquisition**
- Week 1-2: VPS setup, environment configuration
- Week 3-4: Dataset download and initial exploration
- Week 5-8: Data preprocessing and feature engineering

**Months 3-4: Baseline Development**
- Week 9-12: Random Forest, SVM implementation
- Week 13-16: Ensemble models and cross-validation

**Months 5-6: Deep Learning**
- Week 17-20: CNN architecture development
- Week 21-24: LSTM and Transformer models

**Months 7-8: XAI Integration**
- Week 25-28: SHAP and LIME implementation
- Week 29-32: Multi-source telemetry fusion

**Months 9-10: Validation**
- Week 33-36: Multi-cloud testing
- Week 37-40: Attack simulations

**Months 11-12: Finalization**
- Week 41-44: Results analysis
- Week 45-48: Thesis writing and publications

---

## 8. Results Storage Structure

### 8.1 Automated Result Saving Template

```python
import json
import pickle
from datetime import datetime
import os

class ResultManager:
    def __init__(self, vps_path="/home/user/ai-telemetry-research"):
        self.base_path = vps_path
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    def save_model(self, model, model_name, phase):
        """Save trained model"""
        path = f"{self.base_path}/models/{phase}/{model_name}_{self.timestamp}.pkl"
        with open(path, 'wb') as f:
            pickle.dump(model, f)
        return path

    def save_metrics(self, metrics_dict, experiment_name, phase):
        """Save evaluation metrics"""
        path = f"{self.base_path}/results/{phase}/{experiment_name}_metrics_{self.timestamp}.json"
        with open(path, 'w') as f:
            json.dump(metrics_dict, f, indent=4)
        return path

    def save_figure(self, fig, fig_name, phase):
        """Save matplotlib/seaborn figures"""
        path = f"{self.base_path}/results/{phase}/figures/{fig_name}_{self.timestamp}.png"
        fig.savefig(path, dpi=300, bbox_inches='tight')
        return path
```

### 8.2 Backup Strategy

**Daily Backups:**
```bash
#!/bin/bash
# backup_script.sh

BACKUP_DIR="/home/user/backups"
RESEARCH_DIR="/home/user/ai-telemetry-research"
DATE=$(date +%Y%m%d)

# Create backup
tar -czf "$BACKUP_DIR/research_backup_$DATE.tar.gz" "$RESEARCH_DIR"

# Keep only last 30 days of backups
find "$BACKUP_DIR" -name "research_backup_*.tar.gz" -mtime +30 -delete
```

**Crontab entry:**
```bash
0 2 * * * /home/user/scripts/backup_script.sh
```

---

## 9. Step-by-Step Execution Guide

### Day 1: Initial Setup

1. **VPS Setup**
   ```bash
   ssh user@your-vps-ip
   # Follow Section 3.2-3.4
   ```

2. **Google Drive Setup**
   - Create folder: `ai-telemetry-research`
   - Upload notebooks (will be provided next)

3. **Test Connection**
   ```python
   # Test notebook in Colab
   from google.colab import drive
   drive.mount('/content/drive')
   print("Connection successful!")
   ```

### Day 2-7: Data Preparation

1. Run: `01_dataset_download_preparation.ipynb`
2. Run: `02_data_exploration_analysis.ipynb`
3. Run: `03_feature_engineering_telemetry.ipynb`

### Week 2-4: Model Development

Continue with notebooks 04-19 sequentially...

---

## 10. Key Performance Indicators (KPIs) Tracking

### Metrics to Track:

**Detection Performance:**
- Accuracy (Target: ≥98%)
- Precision (Target: ≥96%)
- Recall (Target: ≥95%)
- F1-Score (Target: ≥96%)
- False Positive Rate (Target: ≤2%)

**Operational:**
- Detection Latency (Target: <2 seconds)
- Throughput (events/second)
- Model Training Time
- Inference Time

**XAI:**
- Explanation Consistency Score
- Feature Importance Correlation

---

## 11. Troubleshooting Guide

### Common Issues:

**1. Colab GPU Timeout**
- Solution: Use checkpointing, save model every epoch

**2. VPS Storage Full**
- Solution: Compress old datasets, use external storage

**3. Dataset Download Failures**
- Solution: Use wget with resume flag: `wget -c`

**4. Package Conflicts**
- Solution: Use separate virtual environments per phase

---

## 12. Contact & Support

**Supervisor:** Dr. Mamta Mittal
**Institution:** Delhi Skill and Entrepreneurship University (DSEU)
**Student:** Prabhu Narayan (Roll No. 60222005)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-10
**Status:** Ready for Implementation
