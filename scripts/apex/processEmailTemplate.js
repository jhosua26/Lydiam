const fs = require('fs');

// Read the HTML file
let html = fs.readFileSync('C:/Users/ASUS/Downloads/LydiamEmail/LydiamEmail/Welcome.html', 'utf-8').trim();

// Remove VML namespace declarations that Salesforce email validator rejects
html = html.replace(/ xmlns:v="urn:schemas-microsoft-com:vml"/g, '');
html = html.replace(/ xmlns:o="urn:schemas-microsoft-com:office:office"/g, '');

// Strip invalid HTML5 attributes from <td> and <th> elements
// (border, cellspacing, cellpadding are only valid on <table>, not <td>/<th>)
html = html.replace(/<(t[dh])([^>]+)>/g, (match, tag, attrs) => {
  attrs = attrs.replace(/\s+border="[^"]*"/g, '');
  attrs = attrs.replace(/\s+cellspacing="[^"]*"/g, '');
  attrs = attrs.replace(/\s+cellpadding="[^"]*"/g, '');
  return `<${tag}${attrs}>`;
});

// Make content replacements (order matters: 7867-1XX-01 before 7867-1XX)
// Note: apostrophe in [Client's Name] is Unicode U+2019 (RIGHT SINGLE QUOTATION MARK), not ASCII '
html = html.replace(/\[Client\u2019s Name\]/g, '{{RecipientName}}');
html = html.replace(/7867-1XX-01/g, '{{ReferenceNumber}}-01');
html = html.replace(/7867-1XX/g, '{{ReferenceNumber}}');
html = html.replace(/Jane Doe/g, '{{RecipientName}}');
html = html.replace(/janedoe@gmail\.com/g, '{{RecipientEmail}}');

// Write to the email metadata file
const emailFilePath = 'C:/SFDC_Projects/Lydiam/force-app/main/default/email/unfiled$public/Welcome_Email_Template_1756819238885.email';
fs.writeFileSync(emailFilePath, html, 'utf-8');

// Also write a JSON payload for REST API update (bypasses Salesforce HTML validator)
const jsonPayload = JSON.stringify({ HtmlValue: html });
const jsonPath = 'C:/SFDC_Projects/Lydiam/scripts/apex/updateEmailTemplate.json';
fs.writeFileSync(jsonPath, jsonPayload, 'utf-8');

console.log('Email file written: ' + (fs.statSync(emailFilePath).size / 1024).toFixed(1) + ' KB');
console.log('JSON payload written: ' + (fs.statSync(jsonPath).size / 1024).toFixed(1) + ' KB');
