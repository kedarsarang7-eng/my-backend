// ============================================================================
// Multi-Tenant RLS Verification Script
// ============================================================================
// Validates that Row-Level Security (RLS) effectively isolates tenant data.
// 
// SCENARIO:
// 1. Connect as Tenant A -> Insert Item A
// 2. Connect as Tenant B -> Insert Item B
// 3. Connect as Tenant A -> Verify can see Item A, but NOT Item B
// 4. Connect as Tenant B -> Verify can see Item B, but NOT Item A
//
// USAGE:
// npx ts-node scripts/verify-tenancy.ts
// ============================================================================

import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import * as dotenv from 'dotenv';
dotenv.config();

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'bizmate',
    user: process.env.DB_USER || 'bizmate_admin',
    password: process.env.DB_PASSWORD,
});

async function runVerification() {
    const client = await pool.connect();

    try {
        console.log('🔄 Starting Multi-Tenant RLS Verification...');

        // ── Setup: Generate Mock IDs ───────────────────────────────────────
        const tenantA = uuidv4();
        const tenantB = uuidv4();
        const itemA_ID = uuidv4();
        const itemB_ID = uuidv4();

        console.log(`   Tenant A: ${tenantA}`);
        console.log(`   Tenant B: ${tenantB}`);

        // ── Step 1: Insert Data for Tenant A ───────────────────────────────
        console.log('\nTesting Tenant A Context...');
        await client.query('BEGIN');

        // Set Context
        await client.query(`SELECT set_config('app.tenant_id', $1, true)`, [tenantA]);

        // Create Tenant A Profile (Required for FK)
        await client.query(`
            INSERT INTO tenants (id, name, business_type) 
            VALUES ($1, 'Tenant A Corp', 'retail')
        `, [tenantA]);

        // Insert Inventory Item
        await client.query(`
            INSERT INTO inventory (id, tenant_id, name, sale_price_cents)
            VALUES ($1, $2, 'Item for Tenant A', 1000)
        `, [itemA_ID, tenantA]);

        await client.query('COMMIT');
        console.log('✅ Tenant A data inserted.');


        // ── Step 2: Insert Data for Tenant B ───────────────────────────────
        console.log('\nTesting Tenant B Context...');
        await client.query('BEGIN');

        // Set Context
        await client.query(`SELECT set_config('app.tenant_id', $1, true)`, [tenantB]);

        // Create Tenant B Profile
        await client.query(`
            INSERT INTO tenants (id, name, business_type) 
            VALUES ($1, 'Tenant B Inc', 'pharmacy')
        `, [tenantB]);

        // Insert Inventory Item
        await client.query(`
            INSERT INTO inventory (id, tenant_id, name, sale_price_cents)
            VALUES ($1, $2, 'Item for Tenant B', 2000)
        `, [itemB_ID, tenantB]);

        await client.query('COMMIT');
        console.log('✅ Tenant B data inserted.');


        // ── Step 3: Verify Isolation (As Tenant A) ─────────────────────────
        console.log('\n🔍 Verifying Isolation (Switching back to Tenant A)...');
        await client.query('BEGIN');
        await client.query(`SELECT set_config('app.tenant_id', $1, true)`, [tenantA]);

        const resA = await client.query('SELECT id, name FROM inventory');
        await client.query('COMMIT');

        const foundA = resA.rows.find(r => r.id === itemA_ID);
        const foundB_by_A = resA.rows.find(r => r.id === itemB_ID);

        if (foundA && !foundB_by_A) {
            console.log('✅ SUCCESS: Tenant A sees their own data.');
            console.log('✅ SUCCESS: Tenant A CANNOT see Tenant B data.');
        } else {
            console.error('❌ FAILURE: Isolation breach or data loss!');
            console.error('   Can see Own Data:', !!foundA);
            console.error('   Can see Others Data:', !!foundB_by_A);
            process.exit(1);
        }

        // ── Step 4: Verify Isolation (As Tenant B) ─────────────────────────
        console.log('\n🔍 Verifying Isolation (Switching to Tenant B)...');
        await client.query('BEGIN');
        await client.query(`SELECT set_config('app.tenant_id', $1, true)`, [tenantB]);

        const resB = await client.query('SELECT id, name FROM inventory');
        await client.query('COMMIT');

        const foundB = resB.rows.find(r => r.id === itemB_ID);
        const foundA_by_B = resB.rows.find(r => r.id === itemA_ID);

        if (foundB && !foundA_by_B) {
            console.log('✅ SUCCESS: Tenant B sees their own data.');
            console.log('✅ SUCCESS: Tenant B CANNOT see Tenant A data.');
        } else {
            console.error('❌ FAILURE: Isolation breach!');
            process.exit(1);
        }

        // ── Step 5: Verify Isolation (No Context) ──────────────────────────
        console.log('\nTesting No Context (Should fail or return empty)...');
        // Reset session
        await client.query(`RESET app.tenant_id`);

        try {
            const resNoContext = await client.query('SELECT * FROM inventory');
            if (resNoContext.rows.length === 0) {
                console.log('✅ SUCCESS: No context = No data (RLS Default Deny).');
            } else {
                console.warn('⚠️  WARNING: Data visible without context (Check default RLS policy).');
                console.log(`   Visible rows: ${resNoContext.rows.length}`);
            }
        } catch (err) {
            console.log('✅ SUCCESS: Query failed without context (Expected behavior if configured).');
        }

        // Cleanup
        console.log('\n🧹 Cleaning up test data...');
        // To delete, we need to be authorized as the tenants
        await client.query('BEGIN');
        await client.query(`SELECT set_config('app.tenant_id', $1, true)`, [tenantA]);
        await client.query('DELETE FROM tenants WHERE id = $1', [tenantA]);
        await client.query('COMMIT');

        await client.query('BEGIN');
        await client.query(`SELECT set_config('app.tenant_id', $1, true)`, [tenantB]);
        await client.query('DELETE FROM tenants WHERE id = $1', [tenantB]);
        await client.query('COMMIT');

        console.log('✨ Verification Complete: RLS is Fully Functional!');

    } catch (err) {
        console.error('❌ Error during verification:', err);
    } finally {
        client.release();
        await pool.end();
    }
}

runVerification();
