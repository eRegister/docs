# Upgrading to Bahmni V1

#### ** Upgrading from Bahmni V0.92 to eRegister V1.0**

----------------------------------------------------------------------------------


## 1. System Preparation

### Update the Operating System

```bash
sudo apt update
sudo apt upgrade
```
### Create Working Directory

```bash
sudo mkdir v1
cd v1
```

---
## 2. Clone Required Repositories

### Clone Bahmni Docker Repository

```bash
sudo git clone https://github.com/Lesotho-eRegister-v1/bahmni-docker-ls.git
```

### Clone Standard Configuration Repository

```bash
sudo git clone https://github.com/Lesotho-eRegister-v1/standard-config-ls.git
```

### Clone Concept Dictionary Repository

```bash
sudo git clone https://github.com/eRegister/eregister_concepts_release.git
```
---

## 3. Backup Preparation

### Create Backup Directory

```bash
sudo mkdir bahmni-backup
```

### Clone Existing Bahmni V0.92 Configuration

```bash
cd bahmni-backup
sudo git clone https://github.com/eRegister/bahmni_config092.git
```

### Rename Configuration Folder

```bash
sudo mv bahmni_config092 bahmni_config
```

---

## 4. Database Backup Preparation

### Copy Existing Database Backup into V1 Directory

```bash
sudo cp Maseru_Cross_Border_HC_30_04_2026.sql /v1
```

### Move Backup Directory

```bash
sudo mv backup/ bahmni-backup/
```

### Rename Database Backup

```bash
sudo mv Maseru_Cross_Border_HC_30_04_2026.sql openmrsdb_backup.sql
```

---

## 5. Configure Docker Environment

### Navigate to Bahmni Standard Directory

```bash
cd ~/v1/openmrs/bahmni-docker-ls/bahmni-standard
```

### Edit Environment File

```bash
sudo nano .env.dev
```

### Modify MySQL Version

Comment out:

```bash
OPENMRS_DB_IMAGE_NAME=mysql:8.0
```

Enable:

```bash
OPENMRS_DB_IMAGE_NAME=mysql:5.7
```

---

## 6. Restore Bahmni Backup

```bash
./restore_bahmni_standard.sh /home/openmrs/v1/bahmni-backup
```

---

## 7. Clean Docker Volumes

### List Existing Docker Volumes

```bash
docker volume ls -q
```

### Remove Existing Docker Volumes

```bash
docker volume rm $(docker volume ls -q)
```

### Stop Docker Containers

```bash
docker compose down
```

---

## 8. Start Docker Services

```bash
docker compose up -d
```

### Assign Ownership Permissions

```bash
cd ~
sudo chown -R openmrs:openmrs v1
```

---

## 9. Verify Docker Services

```bash
cd bahmni_docker/
docker compose ps
docker compose stop
```

---

## 10. Start eRegister V1 Services

```bash
cd ~/v1/bahmni-docker-ls/bahmni-standard/
docker compose up -d && docker compose up reports -d
```

---

## 11. Harmonizing Concept Dictionary

### Clone V1 Concept Dictionary Repository

```bash
sudo git clone https://github.com/Lesotho-eRegister-v1/eregister_concepts_release_v1.git
```

### Navigate to Repository

```bash
cd eregister_concepts_release_v1
```

### Copy Concept Dictionary into Database Container

```bash
docker cp omrs_concept_dictionary_v1.sql bahmni-standard-openmrsdb-1:/
```

### Access MySQL Container

```bash
docker exec -it bahmni-standard-openmrsdb-1 bash
```

### Login to MySQL

```bash
mysql -u root -p${MYSQL_ROOT_PASSWORD}
```

### Select OpenMRS Database

```sql
use openmrs
```

### Import Concept Dictionary

```sql
source omrs_concept_dictionary_v1.sql
```

---

## 12. Verification & Validation

### Verify Network Interfaces

```bash
ip a
```

### Verify Running Containers

```bash
docker compose ps
```

### Verification Checklist

- Confirm eRegister services are accessible through browser
- Validate login functionality
- Verify reports module is operational
- Confirm concept dictionary synchronization
- Validate DHIS2 Connector functionality

---

## Notes

- Ensure all backups are verified before proceeding with the upgrade.
- Perform the upgrade during off-peak hours where possible.
- Confirm Docker services are stopped before removing volumes.
- Verify sufficient disk space before importing backups and concept dictionaries.