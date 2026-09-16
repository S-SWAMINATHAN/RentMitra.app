// One-off script: adds the 4 new Combo Plan variants for the redesigned
// Combo Plans page (Smart Living / Family Essentials / Premium Family /
// Ultimate Premium). Idempotent — safe to re-run, skips variants that
// already exist by id under product_id 4 ("Combo Plan").
//
// variant_id is pinned explicitly (9-12) because lib/screens/checkout_screen.dart
// hardcodes these ids for CheckoutProduct.*Combo — letting the identity column
// auto-assign ids here would silently break checkout/pricing lookups.
const pool = require('../src/database.js');

const COMBO_PRODUCT_ID = 4;

const newVariants = [
  { variant_id: 9, variant_name: 'Smart Living Combo', monthly_rent: 2337 },
  { variant_id: 10, variant_name: 'Family Essentials Combo', monthly_rent: 2112 },
  { variant_id: 11, variant_name: 'Premium Family Combo', monthly_rent: 2382 },
  { variant_id: 12, variant_name: 'Ultimate Premium Combo', monthly_rent: 2607 },
];

async function run() {
  for (const v of newVariants) {
    const result = await pool.query(
      `INSERT INTO product_variants (variant_id, product_id, variant_name, monthly_rent)
       OVERRIDING SYSTEM VALUE
       SELECT $1::bigint, $2::int, $3::text, $4::numeric
       WHERE NOT EXISTS (
         SELECT 1 FROM product_variants WHERE variant_id = $1::bigint
       )
       RETURNING variant_id, variant_name, monthly_rent`,
      [v.variant_id, COMBO_PRODUCT_ID, v.variant_name, v.monthly_rent]
    );

    if (result.rows.length > 0) {
      console.log('Inserted:', result.rows[0]);
    } else {
      console.log('Already exists, skipped:', v.variant_name);
    }
  }

  // Re-sync the identity sequence so future auto-assigned inserts don't
  // collide with the explicit ids (9-12) used above.
  await pool.query(
    `SELECT setval(pg_get_serial_sequence('product_variants', 'variant_id'), (SELECT MAX(variant_id) FROM product_variants))`
  );

  const final = await pool.query(
    'SELECT variant_id, product_id, variant_name, monthly_rent, is_active FROM product_variants WHERE product_id = $1 ORDER BY variant_id',
    [COMBO_PRODUCT_ID]
  );
  console.table(final.rows);
  process.exit(0);
}

run().catch((err) => {
  console.error('Failed:', err.message);
  process.exit(1);
});
