'use strict';

/**
 * Sample One Piece products — 3 per category (15 total).
 * Image URLs use the picsum.photos /seed/{slug}/400/400 scheme so each
 * product gets a stable, unique placeholder image.
 */
const PRODUCTS = [
  // ── Figures ─────────────────────────────────────────────────────────────
  {
    name: 'Monkey D. Luffy Gear 5 Figure',
    description:
      'High-detail 20 cm PVC figure of Monkey D. Luffy in his awe-inspiring Gear 5 awakened form. Hand-painted with premium finish; includes a themed base display stand.',
    price: 49.99,
    category: 'Figures',
    imageUrl: 'https://picsum.photos/seed/luffy-gear5/400/400',
    stock: 30,
    rating: 4.9,
  },
  {
    name: 'Roronoa Zoro Three-Sword Style Figure',
    description:
      'Collector-grade 18 cm figure of Zoro mid-stance with all three swords drawn. Sculpted by master craftsmen; perfect for shelves and display cases.',
    price: 44.99,
    category: 'Figures',
    imageUrl: 'https://picsum.photos/seed/zoro-3sword/400/400',
    stock: 25,
    rating: 4.8,
  },
  {
    name: 'Nami "Cat Burglar" Deluxe Figure',
    description:
      'Elegant 16 cm PVC figure of Nami wielding her Clima-Tact staff. Features finely painted detail on her iconic orange hair and Straw Hat Crew tattoo.',
    price: 38.99,
    category: 'Figures',
    imageUrl: 'https://picsum.photos/seed/nami-burglar/400/400',
    stock: 20,
    rating: 4.6,
  },

  // ── Apparel ──────────────────────────────────────────────────────────────
  {
    name: 'Straw Hat Crew Unisex Hoodie',
    description:
      'Premium 320 gsm cotton-blend hoodie featuring the full Straw Hat Crew emblem on the chest. Available in navy, black, and white; machine-washable.',
    price: 54.99,
    category: 'Apparel',
    imageUrl: 'https://picsum.photos/seed/strawhats-hoodie/400/400',
    stock: 60,
    rating: 4.7,
  },
  {
    name: 'Going Merry Graphic T-Shirt',
    description:
      'Soft 180 gsm ringspun cotton tee with a vintage-style ink print of the beloved Going Merry ship sailing the Grand Line. Unisex fit; sizes XS–3XL.',
    price: 24.99,
    category: 'Apparel',
    imageUrl: 'https://picsum.photos/seed/going-merry-tee/400/400',
    stock: 80,
    rating: 4.5,
  },
  {
    name: 'Jolly Roger Embroidered Cap',
    description:
      'Structured six-panel cap with raised Jolly Roger skull embroidery on the front. Adjustable snapback closure; one size fits most.',
    price: 19.99,
    category: 'Apparel',
    imageUrl: 'https://picsum.photos/seed/jolly-roger-cap/400/400',
    stock: 50,
    rating: 4.4,
  },

  // ── Posters ──────────────────────────────────────────────────────────────
  {
    name: 'Thousand Sunny Art Poster',
    description:
      'A3 (297 × 420 mm) high-resolution glossy poster showcasing the Thousand Sunny sailing through a golden sunset on the New World. Printed on 200 gsm coated paper.',
    price: 14.99,
    category: 'Posters',
    imageUrl: 'https://picsum.photos/seed/thousand-sunny-poster/400/400',
    stock: 100,
    rating: 4.8,
  },
  {
    name: 'Wanted — Monkey D. Luffy Bounty Poster',
    description:
      'Reproduction of the iconic WANTED poster for the future King of the Pirates, featuring Luffy\'s 3,000,000,000 Berry bounty. Aged-parchment art print on 170 gsm matte paper.',
    price: 12.99,
    category: 'Posters',
    imageUrl: 'https://picsum.photos/seed/luffy-wanted/400/400',
    stock: 120,
    rating: 4.7,
  },
  {
    name: 'Grand Line Map Wall Art',
    description:
      'Detailed illustrated map of the Grand Line and the Four Blues rendered in a classic nautical cartography style. Available in A2 (420 × 594 mm) framed or unframed.',
    price: 22.99,
    category: 'Posters',
    imageUrl: 'https://picsum.photos/seed/grand-line-map/400/400',
    stock: 45,
    rating: 4.6,
  },

  // ── Keychains ────────────────────────────────────────────────────────────
  {
    name: "Luffy's Straw Hat Metal Keychain",
    description:
      "Die-cast zinc alloy keychain shaped like Luffy's iconic straw hat. Polished gold finish; sturdy lobster-claw clasp; 5 cm diameter.",
    price: 9.99,
    category: 'Keychains',
    imageUrl: 'https://picsum.photos/seed/strawhat-keychain/400/400',
    stock: 200,
    rating: 4.5,
  },
  {
    name: "Zoro's Wado Ichimonji Mini Sword Keychain",
    description:
      'Scaled-down replica of Zoro\'s prized katana Wado Ichimonji. Solid metal construction with white-wrapped handle detail; measures 9 cm overall length.',
    price: 11.99,
    category: 'Keychains',
    imageUrl: 'https://picsum.photos/seed/wado-keychain/400/400',
    stock: 150,
    rating: 4.6,
  },
  {
    name: 'Chopper Chibi Rubber Keychain',
    description:
      'Soft PVC rubber keychain of Tony Tony Chopper in his adorable chibi style, wearing his iconic pink hat. 6 cm tall with metal split ring.',
    price: 7.99,
    category: 'Keychains',
    imageUrl: 'https://picsum.photos/seed/chopper-chibi-keychain/400/400',
    stock: 180,
    rating: 4.7,
  },

  // ── Accessories ──────────────────────────────────────────────────────────
  {
    name: 'Ace Fire Fist Enamel Pin Set',
    description:
      'Set of three hard enamel pins inspired by Portgas D. Ace: a flaming fist, his ASCE tattoo, and the Spade Pirates jolly roger. Gold metal base; butterfly clutch backs.',
    price: 16.99,
    category: 'Accessories',
    imageUrl: 'https://picsum.photos/seed/ace-pin-set/400/400',
    stock: 90,
    rating: 4.8,
  },
  {
    name: 'Straw Hat Pirates Ceramic Mug',
    description:
      '350 ml ceramic mug with a wrap-around print of the Straw Hat Pirates crew silhouette at sea. Microwave and dishwasher safe; arrives in a branded gift box.',
    price: 17.99,
    category: 'Accessories',
    imageUrl: 'https://picsum.photos/seed/strawhats-mug/400/400',
    stock: 70,
    rating: 4.6,
  },
  {
    name: 'Robin "Devil Child" Tote Bag',
    description:
      'Sturdy 10 oz cotton canvas tote bag featuring a minimalist line-art illustration of Nico Robin with her signature flower motif. Dimensions: 38 × 42 cm with 30 cm handles.',
    price: 21.99,
    category: 'Accessories',
    imageUrl: 'https://picsum.photos/seed/robin-tote/400/400',
    stock: 55,
    rating: 4.5,
  },
];

/**
 * Inserts the sample products if the products table is currently empty.
 * Safe to call on every startup — skips silently when data already exists.
 *
 * Requirements: 10.1, 10.2, 10.3
 *
 * @param {import('better-sqlite3').Database} db
 */
function seedProducts(db) {
  const count = db.prepare('SELECT COUNT(*) AS cnt FROM products').get().cnt;
  if (count > 0) {
    console.log(`[seed] Products table already has ${count} row(s). Skipping seed.`);
    return;
  }

  const insert = db.prepare(`
    INSERT INTO products (name, description, price, category, imageUrl, stock, rating)
    VALUES (@name, @description, @price, @category, @imageUrl, @stock, @rating)
  `);

  const insertMany = db.transaction((products) => {
    for (const product of products) {
      insert.run(product);
    }
  });

  insertMany(PRODUCTS);
  console.log(`[seed] Inserted ${PRODUCTS.length} sample products.`);
}

module.exports = { seedProducts };
