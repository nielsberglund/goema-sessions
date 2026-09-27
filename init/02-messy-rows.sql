/*******************************************************************************
   Goema Sessions — deliberately messy rows (data-quality traps)

   Loaded AFTER 01-chinook.sql. Every row here is INTENTIONALLY dirty so the
   live agent can be steered into a mistake on stage and then caught — the
   Act 2 -> Act 3 "where can you trust it?" turn. None of this is real data.

   All planted IDs are >= 9000 so they never collide with real Chinook rows.

   The planted traps:
     1. Duplicate / inconsistently-named artists  -> "how many bands?" / top-artist
     2. Sales of a NULL-genre track               -> revenue-by-genre silently drops rows
     3. Inconsistent billing_country values        -> sales-by-country splits the US
     4. Exact-duplicate invoice line              -> double-counted revenue
     5. Future-dated invoice (year 2099)          -> time-series outlier / bad chart axis
     6. Negative-quantity refund + zero-price comp -> skews units sold & avg price
     7. Invoice header total != sum(its lines)    -> two "correct" totals that disagree

   Quick reset: docker compose down && rm -rf ./goema-pgdata && docker compose up -d
*******************************************************************************/

-- 1. Duplicate / inconsistently-named artists (real "Metallica" is artist_id 50).
INSERT INTO artist (artist_id, name) VALUES
    (9001, 'Metallica '),   -- trailing space
    (9002, 'metallica'),    -- lower-case
    (9003, 'METALLICA');    -- upper-case

-- Give one duplicate a real sales trail so it shows up SEPARATELY from artist 50
-- in any "top artists by revenue" query.
INSERT INTO album (album_id, title, artist_id) VALUES
    (9001, 'Ride the Lightning (Bonus)', 9001);

-- 2. A track with NO genre (genre_id NULL) and no album, yet it gets sold.
INSERT INTO track (track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price) VALUES
    (9001, 'Untitled Demo Take', NULL, 1, NULL, NULL, 201000, NULL, 0.99),
    (9002, 'Fight Fire With Fire (Live)', 9001, 1, 3, 'Hetfield/Ulrich', 273000, NULL, 0.99);

-- 3-7. Invoices for an existing customer (customer_id 1), with dirty attributes.
-- Note billing_country variants and the future date; totals deliberately do not
-- always equal the sum of their lines.
INSERT INTO invoice (invoice_id, customer_id, invoice_date, billing_address, billing_city, billing_state, billing_country, billing_postal_code, total) VALUES
    (9001, 1, TIMESTAMP '2021-06-15 10:00:00', '1 Stage Rd', 'Cape Town',  'WC', 'United States', '8001', 2.97),  -- "United States" not "USA"
    (9002, 1, TIMESTAMP '2021-07-20 11:00:00', '1 Stage Rd', 'Cape Town',  'WC', 'U.S.A.',        '8001', 1.98),  -- another spelling + dup line
    (9003, 1, TIMESTAMP '2021-08-05 12:00:00', '1 Stage Rd', 'Cape Town',  'WC', 'usa ',          '8001', 0.99),  -- trailing space + case
    (9004, 1, TIMESTAMP '2099-12-31 23:59:00', '1 Stage Rd', 'Cape Town',  'WC', 'USA',           '8001', 0.99),  -- future-dated outlier
    (9005, 1, TIMESTAMP '2021-09-01 09:00:00', '1 Stage Rd', 'Cape Town',  'WC', 'USA',           '8001', 0.99);  -- header total != sum(lines)

INSERT INTO invoice_line (invoice_line_id, invoice_id, track_id, unit_price, quantity) VALUES
    -- invoice 9001: a NULL-genre sale + the duplicate-artist track
    (9001, 9001, 9001, 0.99, 1),   -- NULL-genre track -> dropped by genre joins
    (9002, 9001, 9002, 0.99, 1),   -- counts toward 'Metallica ' (9001), not real Metallica (50)
    -- invoice 9002: an EXACT duplicate line (double-counted revenue/units for track 1)
    (9003, 9002, 1, 0.99, 1),
    (9004, 9002, 1, 0.99, 1),
    -- invoice 9003: ordinary line under a dirty country value
    (9005, 9003, 6, 0.99, 1),
    -- invoice 9004: future-dated sale
    (9006, 9004, 6, 0.99, 1),
    -- invoice 9005: a zero-price comp and a negative-quantity refund
    (9007, 9005, 6, 0.00, 1),
    (9008, 9005, 6, 0.99, -1);
