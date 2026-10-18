# HealthSync – Hospital Appointment Scheduler (MySQL)

Database design for a hospital appointment scheduling system, built for an Advanced Database course.

## Schema (`schema.sql`)
- 13 tables (departments, admins, doctors, patients, appointments, and more)
- 5 views, 6 stored procedures, 5 triggers, 14 indexes
- Seed data using placeholder values only

## Run
```bash
mysql -u <user> -p -e "CREATE DATABASE HealthSync_db"
mysql -u <user> -p HealthSync_db < schema.sql
```
Requires MySQL 8+ (developed on 9.6).
