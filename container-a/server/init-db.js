const Database = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, 'anubis.db');
const db = new Database(dbPath);

db.pragma('journal_mode = WAL');

db.exec(`
    CREATE TABLE IF NOT EXISTS scrolls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        author TEXT NOT NULL
    );
`);

const insertScroll = db.prepare('INSERT INTO scrolls (title, content, author) VALUES (?, ?, ?)');

insertScroll.run(
    'The Book of the Dead',
    'A collection of funerary texts that the ancient Egyptians believed would assist the deceased in the afterlife.',
    'Thoth'
);
insertScroll.run(
    'The Pyramid Texts',
    'The oldest known corpus of ancient Egyptian religious texts, dating to the Old Kingdom.',
    'Unas'
);
insertScroll.run(
    'The Amduat',
    'An important ancient Egyptian funerary text that describes the journey of the sun god Ra through the underworld.',
    'Ra'
);
insertScroll.run(
    'The Book of Gates',
    'An ancient text describing the passage through the gates of the underworld, each guarded by a serpent.',
    'Osiris'
);
insertScroll.run(
    'The Hymn to the Aten',
    'A hymn to the sun-disk deity Aten, attributed to Pharaoh Akhenaten.',
    'Akhenaten'
);


db.exec(`
    CREATE TABLE IF NOT EXISTS secrets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT NOT NULL,
        key_value TEXT NOT NULL,
        hidden_path TEXT
    );
`);

const insertSecret = db.prepare('INSERT INTO secrets (key_name, key_value, hidden_path) VALUES (?, ?, ?)');

insertSecret.run(
    'third_fragment',
    'what pharaohs held above all mortals',
    null
);
insertSecret.run(
    'ceremony_location',
    'seek the ceremony that follows death\'s tribunal',
    null
);
insertSecret.run(
    'trial_constancy',
    'the scales listen only to a voice that returns unchanged',
    null
);
insertSecret.run(
    'false_lead_alpha',
    'the southern corridor was always a deception',
    null
);
insertSecret.run(
    'false_lead_beta',
    'not every key fits a lock — some were made to distract',
    null
);

db.close();
console.log('[ANUBIS] Database initialized successfully at:', dbPath);
