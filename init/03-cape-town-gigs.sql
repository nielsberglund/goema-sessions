/*******************************************************************************
   Goema Sessions — Cape Town gig layer  (OPTIONAL)

   A small synthetic live-music layer grafted on top of Chinook so at least one
   question in the set is about THIS city: venues, gigs, and ticket sales.

   Entirely synthetic. No real venue takings, no real people. Venue names are
   well-known Cape Town spots used as flavour only — the numbers are invented.

   SAFE TO DELETE. If you'd rather keep the demo to the plain music-store
   schema, remove this file and reseed; nothing else depends on it.

   Deliberately CLEAN data. All the traps live in 02-messy-rows.sql — this layer
   exists to give the improvisation somewhere local to go, not to add more mess.
   The one honest wrinkle: `capacity` is the room's capacity, so a sold_out gig
   has tickets_sold = capacity and the rest are genuinely under-sold.
*******************************************************************************/

CREATE TABLE venue (
    venue_id     INT          NOT NULL,
    name         VARCHAR(120) NOT NULL,
    suburb       VARCHAR(80)  NOT NULL,
    capacity     INT          NOT NULL,
    CONSTRAINT pk_venue PRIMARY KEY (venue_id)
);

CREATE TABLE gig (
    gig_id       INT          NOT NULL,
    venue_id     INT          NOT NULL,
    artist_id    INT          NOT NULL,
    gig_date     DATE         NOT NULL,
    ticket_price NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_gig PRIMARY KEY (gig_id)
);

CREATE TABLE ticket_sale (
    ticket_sale_id INT           NOT NULL,
    gig_id         INT           NOT NULL,
    sold_at        TIMESTAMP     NOT NULL,
    quantity       INT           NOT NULL,
    unit_price     NUMERIC(10,2) NOT NULL,
    channel        VARCHAR(20)   NOT NULL,   -- 'online' | 'door'
    CONSTRAINT pk_ticket_sale PRIMARY KEY (ticket_sale_id)
);

ALTER TABLE gig ADD CONSTRAINT fk_gig_venue
    FOREIGN KEY (venue_id) REFERENCES venue (venue_id);
ALTER TABLE gig ADD CONSTRAINT fk_gig_artist
    FOREIGN KEY (artist_id) REFERENCES artist (artist_id);
ALTER TABLE ticket_sale ADD CONSTRAINT fk_ticket_sale_gig
    FOREIGN KEY (gig_id) REFERENCES gig (gig_id);

CREATE INDEX ifk_gig_venue      ON gig (venue_id);
CREATE INDEX ifk_gig_artist     ON gig (artist_id);
CREATE INDEX ifk_ticket_sale_gig ON ticket_sale (gig_id);

INSERT INTO venue (venue_id, name, suburb, capacity) VALUES
    (1, 'The Goema Room',        'Bo-Kaap',        220),
    (2, 'Long Street Social',    'City Bowl',      400),
    (3, 'Observatory Bioscope',  'Observatory',    180),
    (4, 'Kalk Bay Sessions',     'Kalk Bay',       120),
    (5, 'Langa Community Hall',  'Langa',          650),
    (6, 'Woodstock Warehouse',   'Woodstock',      900);

-- Artists borrowed from the Chinook catalogue so the layer joins cleanly.
INSERT INTO gig (gig_id, venue_id, artist_id, gig_date, ticket_price) VALUES
    (1, 1, 50,  DATE '2025-02-14', 180.00),
    (2, 2, 22,  DATE '2025-03-01', 250.00),
    (3, 6, 150, DATE '2025-03-22', 320.00),
    (4, 3, 90,  DATE '2025-04-11', 150.00),
    (5, 5, 50,  DATE '2025-05-03', 120.00),
    (6, 4, 76,  DATE '2025-06-20', 200.00),
    (7, 2, 150, DATE '2025-07-18', 250.00),
    (8, 6, 22,  DATE '2025-08-30', 320.00),
    (9, 1, 90,  DATE '2025-09-12', 180.00),
   (10, 5, 76,  DATE '2025-10-04', 120.00);

-- Ticket sales: a mix of online and door, spread over the weeks before each gig.
INSERT INTO ticket_sale (ticket_sale_id, gig_id, sold_at, quantity, unit_price, channel) VALUES
    ( 1,  1, TIMESTAMP '2025-01-20 09:12:00', 120, 180.00, 'online'),
    ( 2,  1, TIMESTAMP '2025-02-14 19:40:00', 100, 180.00, 'door'),
    ( 3,  2, TIMESTAMP '2025-02-02 11:05:00', 210, 250.00, 'online'),
    ( 4,  2, TIMESTAMP '2025-03-01 20:15:00',  95, 250.00, 'door'),
    ( 5,  3, TIMESTAMP '2025-02-18 08:30:00', 540, 320.00, 'online'),
    ( 6,  3, TIMESTAMP '2025-03-22 19:55:00', 210, 320.00, 'door'),
    ( 7,  4, TIMESTAMP '2025-03-15 14:22:00',  95, 150.00, 'online'),
    ( 8,  4, TIMESTAMP '2025-04-11 20:05:00',  40, 150.00, 'door'),
    ( 9,  5, TIMESTAMP '2025-04-02 10:00:00', 480, 120.00, 'online'),
    (10,  5, TIMESTAMP '2025-05-03 18:30:00', 170, 120.00, 'door'),
    (11,  6, TIMESTAMP '2025-05-25 16:45:00',  70, 200.00, 'online'),
    (12,  6, TIMESTAMP '2025-06-20 19:20:00',  50, 200.00, 'door'),
    (13,  7, TIMESTAMP '2025-06-30 09:55:00', 260, 250.00, 'online'),
    (14,  7, TIMESTAMP '2025-07-18 20:40:00', 140, 250.00, 'door'),
    (15,  8, TIMESTAMP '2025-08-01 12:10:00', 610, 320.00, 'online'),
    (16,  8, TIMESTAMP '2025-08-30 19:30:00', 290, 320.00, 'door'),
    (17,  9, TIMESTAMP '2025-08-22 15:00:00', 130, 180.00, 'online'),
    (18,  9, TIMESTAMP '2025-09-12 19:45:00',  60, 180.00, 'door'),
    (19, 10, TIMESTAMP '2025-09-10 08:20:00', 400, 120.00, 'online'),
    (20, 10, TIMESTAMP '2025-10-04 18:50:00', 180, 120.00, 'door');
