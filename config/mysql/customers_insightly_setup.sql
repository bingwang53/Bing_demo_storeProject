-- Local MySQL table for outbound Insightly customer sync
CREATE TABLE IF NOT EXISTS crm_customer_sync (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  local_customer_id VARCHAR(64) NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NULL,
  last_name VARCHAR(100) NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(50) NULL,
  insightly_contact_id BIGINT NULL,
  sync_status ENUM('NEW','SYNCED','FAILED') NOT NULL DEFAULT 'NEW',
  sync_attempts INT NOT NULL DEFAULT 0,
  last_error TEXT NULL,
  last_synced_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_local_customer_id (local_customer_id),
  INDEX idx_sync_status_id (sync_status, id)
);

-- Optional view if your source table is `customers`
-- INSERT INTO crm_customer_sync (local_customer_id, customer_name, first_name, last_name, email, phone, sync_status)
-- SELECT CAST(c.id AS CHAR), c.customer_name, c.first_name, c.last_name, c.email, c.phone, 'NEW'
-- FROM customers c;
