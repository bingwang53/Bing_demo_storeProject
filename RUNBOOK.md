# Bing_Demo_StoreProject Runtime Runbook

## 1) Start Integration Server

1. Open PowerShell.
2. Run:
   ```powershell
   cd C:\SoftwareAG\IntegrationServer\instances\default\bin
   .\startup.bat
   ```
3. Verify:
   - `http://localhost:5555/invoke/wm.server/ping` returns HTTP `200`.

## 2) Confirm Package Is Loaded

1. Open IS Admin: `http://localhost:5555`.
2. Go to `Packages`.
3. Verify `Bing_Demo_StoreProject` is `Enabled`.
4. After local changes, click `Reload` for this package.

## 3) Verify JDBC Pool

1. In IS Admin, go to `Settings -> JDBC Pools`.
2. Verify pool `MySQL_Store` is enabled.
3. Expected URL pattern:
   - `jdbc:mysql://localhost:3306/product_order_db`

## 4) Confirm Key Services

In Designer, verify these services exist:

- `project.bing_demo_store.integrations:sendOrderWebhook`
- `project.bing_demo_store.integrations:pollNewOrders`

## 5) Smoke Test `sendOrderWebhook`

1. Run service manually from Designer.
2. Provide test inputs (`webhookUrl`, `orderId`, `customerId`, `orderAmount`, `orderStatus`, `createdAt`).
3. Check outputs:
   - `success`
   - `statusCode`
   - `responseBody`

## 6) Smoke Test `pollNewOrders`

1. Insert one test order row with `webhook_status='NEW'`.
2. Run:
   - `jdbcPoolAlias=MySQL_Store`
   - `batchSize=1`
   - `webhookUrl=<test endpoint>`
3. Verify DB status changes to:
   - `SENT` on success, or
   - `FAILED` on failure.

## 7) Scheduler Setup

1. In IS Admin, go to `Scheduler`.
2. Add task for:
   - `project.bing_demo_store.integrations:pollNewOrders`
3. Example input:
   - `jdbcPoolAlias=MySQL_Store`
   - `webhookUrl=<your endpoint>`
   - `batchSize=50`
4. Example interval:
   - every `10-30` seconds.

## 8) Logs and Troubleshooting

Primary runtime log:

- `C:\SoftwareAG\IntegrationServer\instances\default\logs\server.log`

Look for keywords:

- `ISS.`
- `ART.`
- `Exception`
- package startup errors

## 9) Three-Way Sync Discipline (Local, IS, GitHub)

1. Make change in Designer/local files.
2. Save (`Ctrl+S`).
3. Reload package in IS Admin.
4. Commit and push:
   ```powershell
   git status
   git add -A
   git commit -m "Describe change"
   git push origin main
   ```

## 10) Quick Recovery

If runtime is unreachable:

1. Restart IS.
2. Recheck ping URL (`localhost:5555`).
3. Reload package in IS Admin.
4. Reconnect Designer server profile.
