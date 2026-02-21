# Local MySQL -> Insightly CRM Customer Sync (Integration Server)

This package now includes customer sync service skeletons:
- `project.bing_demo_store.integrations:pollNewCustomers`
- `project.bing_demo_store.integrations:sendInsightlyCustomer`

Goal: read customer names from local MySQL and create/update customers in Insightly cloud CRM.

## 1) Prepare MySQL table

Run `config/mysql/customers_insightly_setup.sql` in your local MySQL database.

Expected status lifecycle:
- `NEW`: waiting to sync
- `SYNCED`: successfully sent to Insightly
- `FAILED`: previous attempt failed and should be retried

## 2) Create JDBC pool on Integration Server

In IS Admin:
1. Open `Settings -> JDBC Pools`.
2. Create alias, e.g. `LocalMySQLPool`.
3. Use URL format:
   - `jdbc:mysql://localhost:3306/<db_name>?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC`
4. Set username/password and enable the pool.

## 3) Insightly API prerequisites

From Insightly API docs:
- Base URL: `https://api.insightly.com/v3.1`
- Create contact endpoint: `POST /Contacts`
- Update contact endpoint: `PUT /Contacts`
- Auth: HTTP Basic Auth with API key as username and blank password.

In IS, store API key securely (Global Variables or Credential Alias).

## 4) Implement `sendInsightlyCustomer`

Service inputs:
- `insightlyBaseUrl` (example: `https://api.insightly.com/v3.1`)
- `insightlyApiKey`
- `localCustomerId`
- `customerName`
- `firstName`
- `lastName`
- `email`
- `phone`
- `insightlyContactId` (optional; if present, do update)

Flow outline:
1. Build payload document for Insightly `Contact`.
2. `pub.json:documentToJSONString`.
3. If `insightlyContactId` exists, call `PUT /Contacts`; otherwise `POST /Contacts`.
4. Use `pub.client:http` with:
   - `url = <insightlyBaseUrl>/Contacts`
   - `method = post|put`
   - Header `Content-Type=application/json`
   - Header `Authorization=Basic <base64(apiKey + ":")>`
   - body = JSON payload
5. Set outputs:
   - `success`
   - `statusCode`
   - `responseBody`
   - `insightlyContactId` (from response)
   - `errorMessage`

## 5) Implement `pollNewCustomers`

Service inputs:
- `jdbcPoolAlias`
- `insightlyBaseUrl`
- `insightlyApiKey`
- `batchSize`

Flow outline:
1. Query next rows:
   - `SELECT id, local_customer_id, customer_name, first_name, last_name, email, phone, insightly_contact_id`
   - `FROM crm_customer_sync`
   - `WHERE sync_status IN ('NEW','FAILED')`
   - `ORDER BY id ASC LIMIT ?`
2. LOOP rows and invoke `sendInsightlyCustomer`.
3. On success:
   - Update row to `SYNCED`, set `insightly_contact_id`, `last_synced_at=NOW()`, clear `last_error`.
4. On failure:
   - Update row to `FAILED`, increment `sync_attempts`, save `last_error`.
5. Return counters:
   - `processedCount`, `failedCount`, `createdCount`, `updatedCount`.

## 6) Schedule automatic sync

In IS Admin Scheduler:
1. Create a task for `project.bing_demo_store.integrations:pollNewCustomers`.
2. Example inputs:
   - `jdbcPoolAlias=LocalMySQLPool`
   - `insightlyBaseUrl=https://api.insightly.com/v3.1`
   - `insightlyApiKey=<your-api-key>`
   - `batchSize=50`
3. Run every `15` to `30` seconds.

## 7) Quick manual test

1. Insert one `NEW` row into `crm_customer_sync`.
2. Run `pollNewCustomers` from Designer.
3. Verify:
   - Row status changes to `SYNCED`
   - `insightly_contact_id` is populated
   - Contact appears in Insightly.
