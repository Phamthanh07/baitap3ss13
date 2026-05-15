-- =========================
-- 1. TẠO DATABASE
-- =========================
CREATE DATABASE ClinicDB;
USE ClinicDB;

-- =========================
-- 2. TẠO BẢNG MEDICINES
-- =========================
CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY AUTO_INCREMENT,
    medicine_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,0) NOT NULL,
    stock INT DEFAULT 0
);

-- =========================
-- 3. TẠO BẢNG LOG
-- =========================
CREATE TABLE Price_Changes_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    medicine_id INT NOT NULL,
    old_price DECIMAL(10,0),
    new_price DECIMAL(10,0),
    status VARCHAR(20),
    difference DECIMAL(10,0),
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 4. DỮ LIỆU MẪU
-- =========================
INSERT INTO Medicines (medicine_name, price, stock)
VALUES 
('Paracetamol', 10000, 50),
('Amoxicillin', 20000, 30),
('Vitamin C', 15000, 100);

-- =========================
-- 5. TRIGGER CHẶN GIÁ <= 0
-- =========================
DELIMITER $$

CREATE TRIGGER trg_before_update_medicines
BEFORE UPDATE ON Medicines
FOR EACH ROW
BEGIN
    IF NEW.price <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi: Giá thuốc mới không hợp lệ';
    END IF;
END$$

DELIMITER ;

-- =========================
-- 6. TRIGGER GHI LOG THAY ĐỔI GIÁ
-- =========================
DELIMITER $$

CREATE TRIGGER trg_after_update_medicines
AFTER UPDATE ON Medicines
FOR EACH ROW
BEGIN
    DECLARE diff DECIMAL(10,0);
    DECLARE status_change VARCHAR(20);

    -- Chỉ log khi giá thay đổi
    IF NEW.price <> OLD.price THEN

        IF NEW.price > OLD.price THEN
            SET status_change = 'TĂNG GIÁ';
            SET diff = NEW.price - OLD.price;
        ELSE
            SET status_change = 'GIẢM GIÁ';
            SET diff = OLD.price - NEW.price;
        END IF;

        INSERT INTO Price_Changes_Log (
            medicine_id,
            old_price,
            new_price,
            status,
            difference
        )
        VALUES (
            OLD.medicine_id,
            OLD.price,
            NEW.price,
            status_change,
            diff
        );

    END IF;
END$$

DELIMITER ;

-- =========================
-- 7. KIỂM THỬ
-- =========================

-- CASE 1: TĂNG GIÁ (OK)
UPDATE Medicines
SET price = 12000
WHERE medicine_id = 1;

-- CASE 2: GIẢM GIÁ (OK)
UPDATE Medicines
SET price = 18000
WHERE medicine_id = 2;

-- CASE 3: KHÔNG ĐỔI GIÁ (KHÔNG LOG)
UPDATE Medicines
SET stock = 999
WHERE medicine_id = 3;

-- CASE 4: GIÁ SAI (BỊ CHẶN)
UPDATE Medicines
SET price = -5000
WHERE medicine_id = 1;

-- =========================
-- 8. XEM KẾT QUẢ LOG
-- =========================
SELECT * FROM Price_Changes_Log;