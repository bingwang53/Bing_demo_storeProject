-- Add webhook tracking fields to the orders table.
-- Adjust table/column names to match your schema.
ALTER TABLE orders
  ADD COLUMN webhook_status VARCHAR(16) NOT NULL DEFAULT 'NEW',
  ADD COLUMN webhook_attempts INT NOT NULL DEFAULT 0,
  ADD COLUMN webhook_last_error TEXT NULL,
  ADD COLUMN webhook_sent_at DATETIME NULL;

-- Index for polling NEW/FAILED orders efficiently.
CREATE INDEX idx_orders_webhook_status_id ON orders (webhook_status, id);
