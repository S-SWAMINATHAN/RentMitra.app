// One-off script: adds the missing base product variants (AC / Refrigerator /
// Washing Machine) that lib/screens/checkout_screen.dart has always hardcoded
// prices for but that were never inserted into product_variants — so every
// screen backed by PricingProvider (home, category, product detail) showed
// "₹—" for everything except the 1.5 Ton AC (variant_id 1, already seeded).
//
// variant_id is pinned explicitly to match CheckoutProduct.variantId in
// checkout_screen.dart; monthly_rent values match CheckoutProduct.monthlyRent
// in the same file (the pre-existing source of truth for these prices).
const pool = require('../src/database.js');

const AC_PRODUCT_ID = 1;
const FRIDGE_PRODUCT_ID = 2;
const WASHER_PRODUCT_ID = 3;

const newVariants = [
  { variant_id: 2, product_id: AC_PRODUCT_ID, variant_name: '1 Ton', monthly_rent: 999 },
  { variant_id: 3, product_id: FRIDGE_PRODUCT_ID, variant_name: 'Single Door Refrigerator', monthly_rent: 499 },
  { variant_id: 4, product_id: FRIDGE_PRODUCT_ID, variant_name: 'Double Door Refrigerator', monthly_rent: 749 },
  { variant_id: 5, product_id: WASHER_PRODUCT_ID, variant_name: 'Top Load Washing Machine', monthly_rent: 599 },
  { variant_id: 6, product_id: WASHER_PRODUCT_ID, variant_name: 'Front Load Washing Machine', monthly_rent: 899 },
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
      [v.variant_id, v.product_id, v.variant_name, v.monthly_rent]
    );

    if (result.rows.length > 0) {
      console.log('Inserted:', result.rows[0]);
    } else {
      console.log('Already exists, skipped:', v.variant_name);
    }
  }

  await pool.query(
    `SELECT setval(pg_get_serial_sequence('product_variants', 'variant_id'), (SELECT MAX(variant_id) FROM product_variants))`
  );

  const final = await pool.query(
    'SELECT variant_id, product_id, variant_name, monthly_rent, is_active FROM product_variants ORDER BY variant_id'
  );
  console.table(final.rows);
  process.exit(0);
}

run().catch((err) => {
  console.error('Failed:', err.message);
  process.exit(1);
});
