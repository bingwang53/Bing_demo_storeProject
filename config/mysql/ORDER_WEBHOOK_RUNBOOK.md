# MySQL Order -> Webhook (Integration Server)

This package includes service skeletons:
- `project.bing_demo_store.integrations:pollNewOrders`
- `project.bing_demo_store.integrations:sendOrderWebhook`

Use this runbook to wire local MySQL and trigger webhook calls when new orders arrive.

## 1) Prepare MySQL table

Run `config/mysql/orders_webhook_setup.sql` against your local MySQL DB.

Expected behavior:
- New orders start with `webhook_status='NEW'`
- Poller reads `NEW` rows (or `FAILED` rows for retry)
- On success: set `webhook_status='SENT'` and `webhook_sent_at=NOW()`
- On failure: set `webhook_status='FAILED'`, increment attempts, store error

## 2) Create JDBC pool on Integration Server

In IS Admin:
1. Go to `Settings -> JDBC Pools`.
2. Create a pool alias, for example `LocalMySQLPool`.
3. Use MySQL JDBC URL similar to:
   - `jdbc:mysql://localhost:3306/<db_name>?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC`
4. Set username/password and enable the pool.

## 3) Implement `sendOrderWebhook` service

In Designer, edit `project.bing_demo_store.integrations:sendOrderWebhook`:
1. Build payload document from inputs (`orderId`, `customerId`, `orderAmount`, `orderStatus`, `createdAt`).
2. Convert payload to JSON with `pub.json:documentToJSONString`.
3. Call `pub.client:http` with:
   - `url = webhookUrl`
   - `method = post`
   - Header `Content-Type=application/json`
   - Body = generated JSON
4. Map outputs:
   - `statusCode` from HTTP response
   - `responseBody` from HTTP response body
   - `success = true` when status code is 2xx, else `false`

## 4) Implement `pollNewOrders` service

In Designer, edit `project.bing_demo_store.integrations:pollNewOrders`:
1. Read up to `batchSize` rows:
   - `SELECT id, customer_id, amount, status, created_at FROM orders WHERE webhook_status='NEW' ORDER BY id ASC LIMIT ?`
2. LOOP through rows:
   - Invoke `project.bing_demo_store.integrations:sendOrderWebhook`
   - If success:
     - `UPDATE orders SET webhook_status='SENT', webhook_sent_at=NOW(), webhook_last_error=NULL WHERE id=?`
   - Else:
     - `UPDATE orders SET webhook_status='FAILED', webhook_attempts=webhook_attempts+1, webhook_last_error=? WHERE id=?`
3. Return counters:
   - `processedCount`
   - `failedCount`

Use either:
- JDBC Adapter services, or
- `pub.db` built-in services with `jdbcPoolAlias`.

## 5) Schedule automatic trigger

In IS Admin:
1. Go to `Scheduler`.
2. Add task calling `project.bing_demo_store.integrations:pollNewOrders`.
3. Example input:
   - `jdbcPoolAlias=LocalMySQLPool`
   - `webhookUrl=https://<your-webhook-endpoint>`
   - `batchSize=50`
4. Run every `10` seconds (or your preferred interval).

This gives near-real-time webhook triggering for new orders.
