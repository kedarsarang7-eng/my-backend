// ============================================================================
// Secure RLS Wrapper Verification Script
// ============================================================================
// Verifies that:
// 1. describeWithTenant() correctly sets the context.
// 2. Data is isolated between tenants.
// 3. Context is reset after execution (leakage prevention).
// ============================================================================

import { executeWithTenant, getPool } from '../src/config/db.config';
import { onboardTenant } from '../src/services/tenant-onboarding';
import { v4 as uuidv4 } from 'uuid';
import * as dotenv from 'dotenv';
dotenv.config();

async function runVerification() {
    console.log('🔄 Starting Secure RLS Wrapper Verification...');
    const pool = getPool();

    try {
        // 1. Onboard Two Tenants
        console.log('\n📝 Onboarding Tenants...');
        const tenantA = await onboardTenant({ name: 'Tenant A ' + uuidv4().substring(0, 8) });
        const tenantB = await onboardTenant({ name: 'Tenant B ' + uuidv4().substring(0, 8) });
        console.log(`   ✅ Created Tenant A: ${tenantA.id}`);
        console.log(`   ✅ Created Tenant B: ${tenantB.id}`);

        // 2. Insert Data for Tenant A (using secure wrapper)
        console.log('\n➕ Inserting Invoice for Tenant A...');
        await executeWithTenant(tenantA.id, async (client) => {
            await client.query(`
                INSERT INTO invoices (tenant_id, customer_name, amount)
                VALUES ($1, 'Customer A', 100.00)
            `, [tenantA.id]);
        });
        console.log('   ✅ Invoice inserted.');

        // 3. Insert Data for Tenant B
        console.log('\n➕ Inserting Invoice for Tenant B...');
        await executeWithTenant(tenantB.id, async (client) => {
            await client.query(`
                INSERT INTO invoices (tenant_id, customer_name, amount)
                VALUES ($1, 'Customer B', 200.00)
            `, [tenantB.id]);
        });
        console.log('   ✅ Invoice inserted.');

        // 4. Verify Visibility for Tenant A
        console.log('\n🔍 Verifying Visibility for Tenant A...');
        await executeWithTenant(tenantA.id, async (client) => {
            const res = await client.query('SELECT * FROM invoices');
            console.log(`   Rows found: ${res.rows.length}`);

            const hasA = res.rows.some(r => r.customer_name === 'Customer A');
            const hasB = res.rows.some(r => r.customer_name === 'Customer B');

            if (hasA && !hasB) {
                console.log('   ✅ PASS: Tenant A sees only their data.');
            } else {
                console.error('   ❌ FAIL: Visibility check failed for Tenant A');
                console.error(`      Sees A: ${hasA}, Sees B: ${hasB}`);
                process.exit(1);
            }
        });

        // 5. Verify Visibility for Tenant B
        console.log('\n🔍 Verifying Visibility for Tenant B...');
        await executeWithTenant(tenantB.id, async (client) => {
            const res = await client.query('SELECT * FROM invoices');
            console.log(`   Rows found: ${res.rows.length}`);

            const hasB = res.rows.some(r => r.customer_name === 'Customer B');
            const hasA = res.rows.some(r => r.customer_name === 'Customer A');

            if (hasB && !hasA) {
                console.log('   ✅ PASS: Tenant B sees only their data.');
            } else {
                console.error('   ❌ FAIL: Visibility check failed for Tenant B');
                process.exit(1);
            }
        });

        // 6. Verify Context Leakage (Raw Pool Access)
        console.log('\n💧 Verifying Leakage Prevention...');
        // We just ran queries for Tenant B. The connection should have been released and context reset.
        // Let's grab a client from the pool and check usage
        const client = await pool.connect();
        try {
            const res = await client.query(`SELECT current_setting('app.current_tenant', true) as tenant_context`);
            const context = res.rows[0].tenant_context;

            if (context === null) {
                console.log('   ✅ PASS: Connection returned to pool has NO tenant context.');
            } else {
                console.error(`   ❌ FAIL: Connection leaked tenant context: ${context}`);
                process.exit(1);
            }
        } finally {
            client.release();
        }

        console.log('\n✨ All Secure Wrapper Tests Passed!');

    } catch (err) {
        console.error('❌ Test Failed:', err);
    } finally {
        await pool.end();
    }
}

runVerification();
