const crypto = require('crypto');
const express = require('express');
const session = require('express-session');
const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const CORRECT_PASSPHRASE = 'WISDOM_OVER_POWER';
const RELIC_TTL_MS = 90 * 1000;
const rateState = new Map();

const db = new Database(path.join(__dirname, 'anubis.db'), { readonly: false });

function buildClientKey(req, scope) {
    const forwarded = (req.headers['x-forwarded-for'] || '').toString().split(',')[0].trim();
    const ip = forwarded || req.ip || req.socket.remoteAddress || 'unknown';
    return `${scope}:${ip}`;
}

function pruneBucket(key, now) {
    const bucket = rateState.get(key);
    if (!bucket || bucket.expiresAt > now) {
        return bucket;
    }

    rateState.delete(key);
    return null;
}

function createRateLimiter({ scope, windowMs, max, message }) {
    return (req, res, next) => {
        const now = Date.now();
        const key = buildClientKey(req, scope);
        let bucket = pruneBucket(key, now);

        if (!bucket) {
            bucket = { count: 0, expiresAt: now + windowMs };
            rateState.set(key, bucket);
        }

        if (bucket.count >= max) {
            const retryAfter = Math.max(1, Math.ceil((bucket.expiresAt - now) / 1000));
            res.setHeader('Retry-After', retryAfter);
            return res.status(429).json({
                error: message,
                retry_after_seconds: retryAfter
            });
        }

        bucket.count += 1;
        next();
    };
}

app.use(express.json({ limit: '1kb' }));
app.use(express.urlencoded({ extended: true, limit: '1kb' }));


app.use((req, res, next) => {
    if (['PUT', 'DELETE', 'PATCH'].includes(req.method)) {
        return res.status(405).json({ error: 'Method not allowed' });
    }
    next();
});

app.use(session({
    secret: 'anubis_7th_gate_session_key',
    resave: false,
    saveUninitialized: true,
    cookie: { maxAge: 600000 }
}));

// Response header — looks like a catalogue reference, not a "key"
app.use((req, res, next) => {
    res.setHeader('X-Excavation-Ref', 'KH-VII-4');
    next();
});

const publicDir = fs.existsSync(path.join(__dirname, 'public', 'index.html'))
    ? path.join(__dirname, 'public')
    : path.join(__dirname, '..', 'web');

app.use(express.static(publicDir));

app.use('/api/judgement', createRateLimiter({
    scope: 'judgement',
    windowMs: 10 * 60 * 1000,
    max: 8,
    message: 'The scales demand silence before they hear another appeal.'
}));
app.use('/api/relic', createRateLimiter({
    scope: 'relic',
    windowMs: 10 * 60 * 1000,
    max: 4,
    message: 'The relic ward rejects repeated grasping.'
}));

app.get('/api/search', (req, res) => {
    const query = req.query.q;

    if (!query) {
        return res.status(400).json({
            error: 'Missing search parameter. Usage: /api/search?q=<term>'
        });
    }

    if (query.toUpperCase() === 'KH-VII-4') {
        return res.json({
            query,
            count: 1,
            results: [{
                title: 'KH-VII-4 Reference Index',
                content: 'The first sacred fragment was catalogued under excavation reference KH-VII-4. The word recorded was WISDOM.'
            }]
        });
    }

    try {
        const sql = `SELECT id, title, content, author FROM scrolls WHERE title LIKE '%${query}%' OR content LIKE '%${query}%'`;
        const results = db.prepare(sql).all();

        res.json({
            query,
            count: results.length,
            results
        });
    } catch (err) {
        res.status(500).json({
            error: 'Database error',
            message: err.message,
            query
        });
    }
});

app.post('/api/judgement', (req, res) => {
    const passphrase = (req.body.passphrase || '').trim();

    // Initialize session conviction state
    if (typeof req.session.conviction === 'undefined') {
        req.session.conviction = 0;
        // Randomize required count per session (3-5)
        req.session.requiredConviction = 3 + Math.floor(Math.random() * 3);
    }

    // Enforce 30-second cooldown between attempts
    const now = Date.now();
    if (req.session.lastJudgementAt && (now - req.session.lastJudgementAt < 2000)) {
        const waitLeft = Math.ceil((2000 - (now - req.session.lastJudgementAt)) / 1000);
        return res.status(429).json({
            message: 'The scales need time to settle. Return shortly.',
            retry_after_seconds: waitLeft
        });
    }
    req.session.lastJudgementAt = now;

    if (passphrase !== CORRECT_PASSPHRASE) {
        req.session.conviction = 0;
        req.session.relicToken = null;
        req.session.relicIssuedAt = null;
        return res.status(403).json({
            message: 'THE SCALES TIP AGAINST YOU',
            status: 'rejected'
        });
    }

    req.session.conviction += 1;

    if (req.session.conviction < req.session.requiredConviction) {
        return res.status(202).json({
            message: 'TRY AGAIN',
            status: 'pending'
        });
    }

    const token = crypto.randomBytes(12).toString('hex');
    req.session.conviction = 0;
    req.session.relicToken = token;
    req.session.relicIssuedAt = Date.now();

    return res.status(200).json({
        message: 'THE RELIC CHAMBER OPENS',
        status: 'granted',
        download: `/api/relic/${token}`,
        expires_in_seconds: RELIC_TTL_MS / 1000
    });
});

app.get('/api/relic/:token', (req, res) => {
    const keyPath = path.join(__dirname, 'khasem_id_rsa');
    const issuedAt = req.session.relicIssuedAt || 0;

    if (!fs.existsSync(keyPath)) {
        return res.status(200).json({
            message: 'The sacred key has not yet materialized. (Build in Docker to generate)'
        });
    }

    if (!req.session.relicToken || req.params.token !== req.session.relicToken) {
        return res.status(403).json({
            message: 'The relic remains sealed to you.'
        });
    }

    if (Date.now() - issuedAt > RELIC_TTL_MS) {
        req.session.relicToken = null;
        req.session.relicIssuedAt = null;
        return res.status(410).json({
            message: 'The relic seal has expired.'
        });
    }

    req.session.relicToken = null;
    req.session.relicIssuedAt = null;

    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', 'attachment; filename="id_rsa"');
    res.sendFile(keyPath);
});

app.get('/api/download-key', (req, res) => {
    res.status(404).json({
        message: 'The old relic archive has been sealed.'
    });
});

app.use((req, res) => {
    res.status(404).type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lost in the Sands</title>
    <style>
        body { background:#0a0a0a; color:#c9a227; font-family:"Courier New",monospace;
               display:flex; justify-content:center; align-items:center; height:100vh; margin:0; text-align:center; }
        h1 { font-size:2em; margin-bottom:0.5em; }
        p { color:#8b7d3c; }
        .hieroglyph { font-size:3em; margin-bottom:1em; }
    </style>
</head>
<body>
    <div>
        <div class="hieroglyph">&#x13080; &#x130ED; &#x13103;</div>
        <h1>The Sands Have Covered This Path</h1>
        <p>404 - This chamber does not exist.</p>
    </div>
</body>
</html>`);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log('\n[ANUBIS] Server active');
    console.log(`[ANUBIS] Listening on port ${PORT}\n`);
});
