const fs = require('fs');

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('app.js', 'utf8');

const idsInHtml = new Set();
const htmlMatches = html.matchAll(/id=["']([^"']+)["']/g);
for (const match of htmlMatches) {
    idsInHtml.add(match[1]);
}

const appMatches = app.matchAll(/getElementById\(["']([^"']+)["']\)/g);
const missing = new Set();
for (const match of appMatches) {
    const id = match[1];
    if (!idsInHtml.has(id)) {
        missing.add(id);
    }
}

console.log('Missing IDs referenced in app.js:', Array.from(missing));
