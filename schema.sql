-- ============================================================
--  HealthSync Hospital Appointment Scheduler
--  Advanced Database Project - VCU CMSC
--  MySQL 9.6 | Database: HealthSync_db
-- ============================================================

USE HealthSync_db;

-- ============================================================
-- SECTION 1: TABLES
-- ============================================================

-- 1. Departments
CREATE TABLE departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    floor_number    INT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Admins
CREATE TABLE admins (
    admin_id        INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(50) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    full_name       VARCHAR(100),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Doctors
CREATE TABLE doctors (
    doctor_id       INT AUTO_INCREMENT PRIMARY KEY,
    department_id   INT NOT NULL,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    username        VARCHAR(50) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    license_number  VARCHAR(50) NOT NULL UNIQUE,
    specialization  VARCHAR(100),
    joining_date    DATE,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctor_dept FOREIGN KEY (department_id)
        REFERENCES departments(department_id) ON DELETE RESTRICT
);

-- 4. Patients
CREATE TABLE patients (
    patient_id      INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    phone           VARCHAR(20),
    date_of_birth   DATE,
    gender          ENUM('Male','Female','Other'),
    blood_type      ENUM('A+','A-','B+','B-','O+','O-','AB+','AB-'),
    address         TEXT,
    insurance_id    VARCHAR(50),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Doctor Availability Schedule
CREATE TABLE doctor_schedules (
    schedule_id     INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id       INT NOT NULL,
    day_of_week     ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    slot_duration   INT DEFAULT 30,
    is_available    BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_schedule_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    CONSTRAINT chk_schedule_time CHECK (end_time > start_time)
);

-- 6. Appointments
CREATE TABLE appointments (
    appointment_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT NOT NULL,
    doctor_id        INT NOT NULL,
    department_id    INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INT DEFAULT 30,
    type             ENUM('In-Person','Video') DEFAULT 'In-Person',
    status           ENUM('Scheduled','Completed','Cancelled','No-Show') DEFAULT 'Scheduled',
    reason           TEXT,
    notes            TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appt_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appt_dept FOREIGN KEY (department_id)
        REFERENCES departments(department_id) ON DELETE RESTRICT
);

-- 7. Medical Records
CREATE TABLE medical_records (
    record_id       INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id  INT NOT NULL UNIQUE,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    diagnosis       TEXT NOT NULL,
    treatment       TEXT,
    notes           TEXT,
    follow_up_date  DATE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_record_appt    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    CONSTRAINT fk_record_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_record_doctor  FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id) ON DELETE RESTRICT
);

-- 8. Medicines
CREATE TABLE medicines (
    medicine_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    category        VARCHAR(50),
    unit            VARCHAR(20) DEFAULT 'mg',
    description     TEXT
);

-- 9. Prescriptions
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    record_id       INT NOT NULL,
    patient_id      INT NOT NULL,
    doctor_id       INT NOT NULL,
    medicine_id     INT NOT NULL,
    dosage          VARCHAR(50) NOT NULL,
    frequency       ENUM('Once daily','Twice daily','Three times daily','Once at night','As needed') NOT NULL,
    duration_days   INT NOT NULL,
    refills         INT DEFAULT 0,
    instructions    TEXT,
    issued_date     DATE DEFAULT (CURDATE()),
    status          ENUM('Active','Completed','Cancelled') DEFAULT 'Active',
    CONSTRAINT fk_presc_record   FOREIGN KEY (record_id)
        REFERENCES medical_records(record_id) ON DELETE CASCADE,
    CONSTRAINT fk_presc_patient  FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_presc_doctor   FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    CONSTRAINT fk_presc_medicine FOREIGN KEY (medicine_id)
        REFERENCES medicines(medicine_id) ON DELETE RESTRICT,
    CONSTRAINT chk_duration CHECK (duration_days > 0),
    CONSTRAINT chk_refills  CHECK (refills >= 0)
);

-- 10. Billing
CREATE TABLE billing (
    bill_id             INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id      INT NOT NULL UNIQUE,
    patient_id          INT NOT NULL,
    total_amount        DECIMAL(10,2) NOT NULL,
    insurance_coverage  DECIMAL(10,2) DEFAULT 0.00,
    patient_due         DECIMAL(10,2) GENERATED ALWAYS AS (total_amount - insurance_coverage) STORED,
    payment_status      ENUM('Unpaid','Paid','Partial','Waived') DEFAULT 'Unpaid',
    payment_date        DATE,
    payment_method      ENUM('Cash','Card','Insurance','Online'),
    notes               TEXT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_appt    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id) ON DELETE RESTRICT,
    CONSTRAINT fk_bill_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON DELETE RESTRICT,
    CONSTRAINT chk_total     CHECK (total_amount >= 0),
    CONSTRAINT chk_insurance CHECK (insurance_coverage >= 0),
    CONSTRAINT chk_coverage  CHECK (insurance_coverage <= total_amount)
);

-- 11. Audit Log
CREATE TABLE audit_log (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    table_name  VARCHAR(50) NOT NULL,
    record_id   INT NOT NULL,
    action      ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    changed_by  VARCHAR(100),
    old_values  JSON,
    new_values  JSON,
    changed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Notifications
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT,
    doctor_id       INT,
    type            ENUM('Appointment Reminder','Prescription Expiry','Bill Due','General') DEFAULT 'General',
    message         TEXT NOT NULL,
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_doctor  FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- 13. Hospital Settings
CREATE TABLE hospital_settings (
    setting_id        INT AUTO_INCREMENT PRIMARY KEY,
    hospital_name     VARCHAR(100) DEFAULT 'HealthSync General Hospital',
    email             VARCHAR(100),
    phone             VARCHAR(20),
    address           TEXT,
    slot_duration     INT DEFAULT 30,
    work_start        TIME DEFAULT '08:00:00',
    work_end          TIME DEFAULT '18:00:00',
    max_appointments  INT DEFAULT 12,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- ============================================================
-- SECTION 2: INDEXES
-- ============================================================

CREATE INDEX idx_appt_date        ON appointments(appointment_date);
CREATE INDEX idx_appt_doctor      ON appointments(doctor_id);
CREATE INDEX idx_appt_patient     ON appointments(patient_id);
CREATE INDEX idx_appt_status      ON appointments(status);
CREATE INDEX idx_appt_doctor_date ON appointments(doctor_id, appointment_date);
CREATE INDEX idx_record_patient   ON medical_records(patient_id);
CREATE INDEX idx_record_doctor    ON medical_records(doctor_id);
CREATE INDEX idx_presc_patient    ON prescriptions(patient_id);
CREATE INDEX idx_presc_status     ON prescriptions(status);
CREATE INDEX idx_bill_patient     ON billing(patient_id);
CREATE INDEX idx_bill_status      ON billing(payment_status);
CREATE INDEX idx_doctor_dept      ON doctors(department_id);
CREATE INDEX idx_audit_table      ON audit_log(table_name, record_id);
CREATE INDEX idx_notif_patient    ON notifications(patient_id);


-- ============================================================
-- SECTION 3: VIEWS
-- ============================================================

-- View 1: Full appointment details
CREATE VIEW vw_appointment_details AS
SELECT
    a.appointment_id,
    a.appointment_date,
    a.appointment_time,
    a.type,
    a.status,
    a.reason,
    a.notes,
    CONCAT(p.first_name,' ',p.last_name)          AS patient_name,
    p.email                                        AS patient_email,
    p.phone                                        AS patient_phone,
    CONCAT('Dr. ',d.first_name,' ',d.last_name)   AS doctor_name,
    d.specialization,
    dep.name                                       AS department,
    a.created_at
FROM appointments a
JOIN patients    p   ON a.patient_id    = p.patient_id
JOIN doctors     d   ON a.doctor_id     = d.doctor_id
JOIN departments dep ON a.department_id = dep.department_id;

-- View 2: Today's appointments
CREATE VIEW vw_todays_appointments AS
SELECT * FROM vw_appointment_details
WHERE appointment_date = CURDATE()
ORDER BY appointment_time;

-- View 3: Active prescriptions with medicine info
CREATE VIEW vw_active_prescriptions AS
SELECT
    pr.prescription_id,
    CONCAT(p.first_name,' ',p.last_name)         AS patient_name,
    CONCAT('Dr. ',d.first_name,' ',d.last_name)  AS doctor_name,
    m.name                                        AS medicine_name,
    m.category,
    pr.dosage,
    pr.frequency,
    pr.duration_days,
    pr.issued_date,
    DATE_ADD(pr.issued_date, INTERVAL pr.duration_days DAY) AS expiry_date,
    pr.refills,
    pr.instructions,
    pr.status
FROM prescriptions pr
JOIN patients  p ON pr.patient_id  = p.patient_id
JOIN doctors   d ON pr.doctor_id   = d.doctor_id
JOIN medicines m ON pr.medicine_id = m.medicine_id
WHERE pr.status = 'Active';

-- View 4: Patient billing summary
CREATE VIEW vw_patient_billing_summary AS
SELECT
    p.patient_id,
    CONCAT(p.first_name,' ',p.last_name)  AS patient_name,
    p.email,
    COUNT(b.bill_id)                       AS total_bills,
    SUM(b.total_amount)                    AS total_charged,
    SUM(b.insurance_coverage)              AS total_insurance,
    SUM(b.patient_due)                     AS total_patient_due,
    SUM(CASE WHEN b.payment_status = 'Paid'   THEN b.patient_due ELSE 0 END) AS total_paid,
    SUM(CASE WHEN b.payment_status = 'Unpaid' THEN b.patient_due ELSE 0 END) AS outstanding
FROM patients p
LEFT JOIN billing b ON p.patient_id = b.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name, p.email;

-- View 5: Doctor workload
CREATE VIEW vw_doctor_workload AS
SELECT
    d.doctor_id,
    CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name,
    d.specialization,
    dep.name                                      AS department,
    COUNT(a.appointment_id)                       AS total_appointments,
    SUM(CASE WHEN a.appointment_date = CURDATE() THEN 1 ELSE 0 END) AS today_appointments,
    SUM(CASE WHEN a.status = 'Completed'          THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN a.status = 'Cancelled'          THEN 1 ELSE 0 END) AS cancelled
FROM doctors d
JOIN departments dep ON d.department_id = dep.department_id
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization, dep.name;


-- ============================================================
-- SECTION 4: STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- Procedure 1: Book an appointment
CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id      INT,
    IN p_doctor_id       INT,
    IN p_department_id   INT,
    IN p_date            DATE,
    IN p_time            TIME,
    IN p_type            VARCHAR(20),
    IN p_reason          TEXT,
    OUT p_appointment_id INT,
    OUT p_message        VARCHAR(255)
)
BEGIN
    DECLARE conflict_count INT DEFAULT 0;

    -- Check if doctor already has appointment at same date/time
    SELECT COUNT(*) INTO conflict_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND appointment_time = p_time
      AND status = 'Scheduled';

    IF conflict_count > 0 THEN
        SET p_appointment_id = 0;
        SET p_message = 'Doctor is not available at this time. Please choose another slot.';
    ELSE
        INSERT INTO appointments (patient_id, doctor_id, department_id, appointment_date, appointment_time, type, reason)
        VALUES (p_patient_id, p_doctor_id, p_department_id, p_date, p_time, p_type, p_reason);
        SET p_appointment_id = LAST_INSERT_ID();
        SET p_message = 'Appointment booked successfully.';

        -- Create notification for patient
        INSERT INTO notifications (patient_id, type, message)
        VALUES (p_patient_id, 'Appointment Reminder',
            CONCAT('Your appointment is confirmed for ', p_date, ' at ', p_time));
    END IF;
END$$

-- Procedure 2: Cancel an appointment
CREATE PROCEDURE sp_cancel_appointment(
    IN  p_appointment_id INT,
    OUT p_message        VARCHAR(255)
)
BEGIN
    DECLARE current_status VARCHAR(20);

    SELECT status INTO current_status
    FROM appointments WHERE appointment_id = p_appointment_id;

    IF current_status = 'Completed' THEN
        SET p_message = 'Cannot cancel a completed appointment.';
    ELSEIF current_status = 'Cancelled' THEN
        SET p_message = 'Appointment is already cancelled.';
    ELSE
        UPDATE appointments
        SET status = 'Cancelled'
        WHERE appointment_id = p_appointment_id;
        SET p_message = 'Appointment cancelled successfully.';
    END IF;
END$$

-- Procedure 3: Complete appointment and generate bill
CREATE PROCEDURE sp_complete_appointment(
    IN  p_appointment_id  INT,
    IN  p_diagnosis       TEXT,
    IN  p_treatment       TEXT,
    IN  p_notes           TEXT,
    IN  p_total_amount    DECIMAL(10,2),
    IN  p_insurance       DECIMAL(10,2),
    OUT p_message         VARCHAR(255)
)
BEGIN
    DECLARE v_patient_id INT;
    DECLARE v_doctor_id  INT;

    SELECT patient_id, doctor_id INTO v_patient_id, v_doctor_id
    FROM appointments WHERE appointment_id = p_appointment_id;

    START TRANSACTION;
        -- Mark appointment as completed
        UPDATE appointments
        SET status = 'Completed'
        WHERE appointment_id = p_appointment_id;

        -- Create medical record
        INSERT INTO medical_records (appointment_id, patient_id, doctor_id, diagnosis, treatment, notes)
        VALUES (p_appointment_id, v_patient_id, v_doctor_id, p_diagnosis, p_treatment, p_notes);

        -- Generate bill
        INSERT INTO billing (appointment_id, patient_id, total_amount, insurance_coverage)
        VALUES (p_appointment_id, v_patient_id, p_total_amount, p_insurance);

        -- Notify patient of bill
        INSERT INTO notifications (patient_id, type, message)
        VALUES (v_patient_id, 'Bill Due',
            CONCAT('Your bill of $', (p_total_amount - p_insurance), ' is now due.'));

    COMMIT;
    SET p_message = 'Appointment completed and bill generated.';
END$$

-- Procedure 4: Issue a prescription
CREATE PROCEDURE sp_issue_prescription(
    IN  p_record_id     INT,
    IN  p_patient_id    INT,
    IN  p_doctor_id     INT,
    IN  p_medicine_id   INT,
    IN  p_dosage        VARCHAR(50),
    IN  p_frequency     VARCHAR(50),
    IN  p_duration      INT,
    IN  p_refills       INT,
    IN  p_instructions  TEXT,
    OUT p_message       VARCHAR(255)
)
BEGIN
    INSERT INTO prescriptions
        (record_id, patient_id, doctor_id, medicine_id, dosage, frequency, duration_days, refills, instructions)
    VALUES
        (p_record_id, p_patient_id, p_doctor_id, p_medicine_id, p_dosage, p_frequency, p_duration, p_refills, p_instructions);

    -- Notify patient
    INSERT INTO notifications (patient_id, type, message)
    VALUES (p_patient_id, 'Prescription Expiry',
        CONCAT('New prescription issued. Valid for ', p_duration, ' days.'));

    SET p_message = 'Prescription issued successfully.';
END$$

-- Procedure 5: Get patient full history
CREATE PROCEDURE sp_get_patient_history(
    IN p_patient_id INT
)
BEGIN
    -- Appointments
    SELECT a.appointment_id, a.appointment_date, a.appointment_time,
           a.type, a.status, a.reason,
           CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name,
           dep.name AS department
    FROM appointments a
    JOIN doctors d ON a.doctor_id = d.doctor_id
    JOIN departments dep ON a.department_id = dep.department_id
    WHERE a.patient_id = p_patient_id
    ORDER BY a.appointment_date DESC;

    -- Medical Records
    SELECT mr.record_id, mr.diagnosis, mr.treatment, mr.notes,
           mr.follow_up_date, mr.created_at,
           CONCAT('Dr. ',d.first_name,' ',d.last_name) AS doctor_name
    FROM medical_records mr
    JOIN doctors d ON mr.doctor_id = d.doctor_id
    WHERE mr.patient_id = p_patient_id
    ORDER BY mr.created_at DESC;

    -- Prescriptions
    SELECT pr.prescription_id, m.name AS medicine, pr.dosage,
           pr.frequency, pr.duration_days, pr.issued_date, pr.status,
           DATE_ADD(pr.issued_date, INTERVAL pr.duration_days DAY) AS expiry_date
    FROM prescriptions pr
    JOIN medicines m ON pr.medicine_id = m.medicine_id
    WHERE pr.patient_id = p_patient_id
    ORDER BY pr.issued_date DESC;
END$$

-- Procedure 6: Get doctor schedule for a week
CREATE PROCEDURE sp_get_doctor_schedule(
    IN p_doctor_id INT,
    IN p_start_date DATE
)
BEGIN
    SELECT
        a.appointment_id,
        a.appointment_date,
        a.appointment_time,
        a.status,
        a.type,
        CONCAT(p.first_name,' ',p.last_name) AS patient_name,
        a.reason
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.doctor_id = p_doctor_id
      AND a.appointment_date BETWEEN p_start_date AND DATE_ADD(p_start_date, INTERVAL 6 DAY)
    ORDER BY a.appointment_date, a.appointment_time;
END$$

DELIMITER ;


-- ============================================================
-- SECTION 5: TRIGGERS
-- ============================================================

DELIMITER $$

-- Trigger 1: Prevent double booking
CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE conflict INT DEFAULT 0;
    SELECT COUNT(*) INTO conflict
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
      AND appointment_date = NEW.appointment_date
      AND appointment_time = NEW.appointment_time
      AND status = 'Scheduled';
    IF conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This time slot is already booked for the selected doctor.';
    END IF;
END$$

-- Trigger 2: Auto log on appointment update
CREATE TRIGGER trg_audit_appointment_update
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
    VALUES (
        'appointments',
        NEW.appointment_id,
        'UPDATE',
        JSON_OBJECT('status', OLD.status, 'date', OLD.appointment_date),
        JSON_OBJECT('status', NEW.status, 'date', NEW.appointment_date)
    );
END$$

-- Trigger 3: Auto log new patient registration
CREATE TRIGGER trg_audit_patient_insert
AFTER INSERT ON patients
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, record_id, action, new_values)
    VALUES (
        'patients',
        NEW.patient_id,
        'INSERT',
        JSON_OBJECT('name', CONCAT(NEW.first_name,' ',NEW.last_name), 'email', NEW.email)
    );
END$$

-- Trigger 4: Auto expire prescriptions past their duration
CREATE TRIGGER trg_auto_expire_prescription
BEFORE UPDATE ON prescriptions
FOR EACH ROW
BEGIN
    IF NEW.status = 'Active' AND DATE_ADD(NEW.issued_date, INTERVAL NEW.duration_days DAY) < CURDATE() THEN
        SET NEW.status = 'Completed';
    END IF;
END$$

-- Trigger 5: Auto log doctor status changes
CREATE TRIGGER trg_audit_doctor_update
AFTER UPDATE ON doctors
FOR EACH ROW
BEGIN
    IF OLD.is_active != NEW.is_active THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
        VALUES (
            'doctors',
            NEW.doctor_id,
            'UPDATE',
            JSON_OBJECT('is_active', OLD.is_active),
            JSON_OBJECT('is_active', NEW.is_active)
        );
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SECTION 6: SEED DATA
-- ============================================================

-- Departments
INSERT INTO departments (name, description, floor_number) VALUES
('Cardiology',       'Heart and cardiovascular care',     2),
('Neurology',        'Brain and nervous system care',     3),
('Dermatology',      'Skin and hair care',                1),
('General Physician','General health and wellness',       1),
('Orthopedics',      'Bone and joint care',               4),
('Pediatrics',       'Child and infant healthcare',       2);

-- Admin
INSERT INTO admins (username, password_hash, email, full_name) VALUES
('admin', '$2b$10$examplehashedpassword', 'admin@healthsync.com', 'System Administrator');

-- Doctors (password: doctor123 - hashed in real app)
INSERT INTO doctors (department_id, first_name, last_name, username, password_hash, email, phone, license_number, specialization, joining_date) VALUES
(1, 'James',  'Miller', 'dr.miller',  '$2b$10$examplehashedpassword', 'j.miller@healthsync.com',  '+1-555-1001', 'MD-10001', 'Cardiology',       '2020-01-15'),
(4, 'Sarah',  'Lee',    'dr.lee',     '$2b$10$examplehashedpassword', 's.lee@healthsync.com',     '+1-555-1002', 'MD-10002', 'General Physician', '2019-03-10'),
(3, 'Raj',    'Kumar',  'dr.kumar',   '$2b$10$examplehashedpassword', 'r.kumar@healthsync.com',   '+1-555-1003', 'MD-10003', 'Dermatology',       '2021-06-01'),
(2, 'Emily',  'Chen',   'dr.chen',    '$2b$10$examplehashedpassword', 'e.chen@healthsync.com',    '+1-555-1004', 'MD-10004', 'Neurology',         '2018-09-20'),
(6, 'Nina',   'Patel',  'dr.patel',   '$2b$10$examplehashedpassword', 'n.patel@healthsync.com',   '+1-555-1005', 'MD-10005', 'Pediatrics',        '2023-01-05'),
(5, 'David',  'Brown',  'dr.brown',   '$2b$10$examplehashedpassword', 'd.brown@healthsync.com',   '+1-555-1006', 'MD-10006', 'Orthopedics',       '2017-11-30');

-- Patients (password: patient123 - hashed in real app)
INSERT INTO patients (first_name, last_name, email, password_hash, phone, date_of_birth, gender, blood_type, address) VALUES
('John',    'Doe',     'john.doe@email.com',     '$2b$10$examplehashedpassword', '+1-555-2001', '1990-05-15', 'Male',   'O+', '123 Main St, Richmond, VA'),
('Maria',   'Santos',  'maria.s@email.com',      '$2b$10$examplehashedpassword', '+1-555-2002', '1974-08-22', 'Female', 'A+', '456 Oak Ave, Richmond, VA'),
('Priya',   'Sharma',  'priya.sh@email.com',     '$2b$10$examplehashedpassword', '+1-555-2003', '1995-03-10', 'Female', 'B+', '789 Pine Rd, Richmond, VA'),
('Daniel',  'Chen',    'daniel.c@email.com',     '$2b$10$examplehashedpassword', '+1-555-2004', '1988-11-30', 'Male',   'AB-','321 Elm St, Richmond, VA'),
('Sarah',   'Johnson', 'sarah.j@email.com',      '$2b$10$examplehashedpassword', '+1-555-2005', '2000-07-04', 'Female', 'O-', '654 Cedar Blvd, Richmond, VA'),
('Tom',     'Wilson',  'tom.w@email.com',        '$2b$10$examplehashedpassword', '+1-555-2006', '1965-12-18', 'Male',   'A-', '987 Maple Dr, Richmond, VA'),
('Lisa',    'Ray',     'lisa.r@email.com',       '$2b$10$examplehashedpassword', '+1-555-2007', '1985-09-25', 'Female', 'B-', '147 Birch Ln, Richmond, VA'),
('Robert',  'Kim',     'robert.k@email.com',     '$2b$10$examplehashedpassword', '+1-555-2008', '1978-04-12', 'Male',   'AB+','258 Walnut St, Richmond, VA');

-- Medicines
INSERT INTO medicines (name, category, unit) VALUES
('Metformin',    'Antidiabetic',  'mg'),
('Lisinopril',   'Antihypertensive','mg'),
('Atorvastatin', 'Statin',        'mg'),
('Vitamin D3',   'Supplement',    'IU'),
('Aspirin',      'Antiplatelet',  'mg'),
('Amoxicillin',  'Antibiotic',    'mg'),
('Ibuprofen',    'NSAID',         'mg'),
('Omeprazole',   'PPI',           'mg');

-- Doctor Schedules
INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time) VALUES
(1, 'Monday',    '09:00:00', '17:00:00'),
(1, 'Wednesday', '09:00:00', '17:00:00'),
(1, 'Friday',    '09:00:00', '13:00:00'),
(2, 'Monday',    '08:00:00', '16:00:00'),
(2, 'Tuesday',   '08:00:00', '16:00:00'),
(2, 'Thursday',  '08:00:00', '16:00:00'),
(3, 'Tuesday',   '10:00:00', '18:00:00'),
(3, 'Thursday',  '10:00:00', '18:00:00'),
(4, 'Monday',    '09:00:00', '17:00:00'),
(4, 'Wednesday', '09:00:00', '17:00:00'),
(5, 'Tuesday',   '08:00:00', '14:00:00'),
(5, 'Friday',    '08:00:00', '14:00:00'),
(6, 'Monday',    '09:00:00', '17:00:00'),
(6, 'Thursday',  '09:00:00', '17:00:00');

-- Appointments
INSERT INTO appointments (patient_id, doctor_id, department_id, appointment_date, appointment_time, type, status, reason) VALUES
(1, 1, 1, '2026-04-05', '09:00:00', 'In-Person', 'Scheduled',  'Hypertension follow-up'),
(2, 1, 1, '2026-04-05', '10:30:00', 'In-Person', 'Scheduled',  'Chest pain evaluation'),
(3, 2, 4, '2026-04-07', '08:00:00', 'Video',      'Scheduled',  'General checkup'),
(4, 3, 3, '2026-04-08', '10:00:00', 'In-Person', 'Scheduled',  'Skin rash'),
(5, 4, 2, '2026-04-09', '09:00:00', 'In-Person', 'Scheduled',  'Headaches'),
(1, 2, 4, '2026-03-10', '08:00:00', 'In-Person', 'Completed',  'Diabetes management'),
(2, 1, 1, '2026-03-15', '09:00:00', 'In-Person', 'Completed',  'Heart checkup'),
(6, 1, 1, '2026-03-20', '10:00:00', 'In-Person', 'Completed',  'Stress test'),
(7, 4, 2, '2026-03-22', '11:00:00', 'In-Person', 'Completed',  'Arrhythmia review'),
(8, 1, 1, '2026-03-28', '09:00:00', 'In-Person', 'Completed',  'ECG review');

-- Medical Records (for completed appointments)
INSERT INTO medical_records (appointment_id, patient_id, doctor_id, diagnosis, treatment, notes) VALUES
(6,  1, 2, 'Type 2 Diabetes',     'Metformin 500mg twice daily',   'Monitor blood sugar weekly'),
(7,  2, 1, 'Hypertension',        'Lisinopril 10mg once daily',    'Reduce sodium intake'),
(8,  6, 1, 'Normal stress test',  'No medication required',        'Follow up in 6 months'),
(9,  7, 4, 'Atrial Fibrillation', 'Aspirin 81mg once daily',       'Holter monitor ordered'),
(10, 8, 1, 'High Cholesterol',    'Atorvastatin 20mg once nightly','Diet changes advised');

-- Prescriptions
INSERT INTO prescriptions (record_id, patient_id, doctor_id, medicine_id, dosage, frequency, duration_days, refills, instructions) VALUES
(1, 1, 2, 1, '500mg', 'Twice daily',    90, 2, 'Take with food'),
(2, 2, 1, 2, '10mg',  'Once daily',     30, 1, 'Take in morning'),
(3, 6, 1, 7, '400mg', 'As needed',      14, 0, 'Take with food, max 3x daily'),
(4, 7, 4, 5, '81mg',  'Once daily',     90, 3, 'Take with water'),
(5, 8, 1, 3, '20mg',  'Once at night',  90, 2, 'Take at bedtime');

-- Billing
INSERT INTO billing (appointment_id, patient_id, total_amount, insurance_coverage, payment_status) VALUES
(6,  1, 150.00, 120.00, 'Paid'),
(7,  2, 300.00, 240.00, 'Unpaid'),
(8,  6, 600.00, 480.00, 'Paid'),
(9,  7, 250.00, 200.00, 'Unpaid'),
(10, 8, 200.00, 160.00, 'Paid');

-- Hospital Settings
INSERT INTO hospital_settings (hospital_name, email, phone, address, slot_duration, work_start, work_end, max_appointments)
VALUES ('HealthSync General Hospital', 'admin@healthsync.com', '+1-555-0000', '456 Healthcare Blvd, Richmond, VA 23220', 30, '08:00:00', '18:00:00', 12);

-- ============================================================
-- DONE! HealthSync_db is ready.
-- ============================================================
SELECT 'HealthSync database setup complete!' AS Status;
