DROP INDEX idx_device_customer_id;
DROP TRIGGER IF EXISTS update_device_updated_at ON device;
DROP TABLE IF EXISTS device;