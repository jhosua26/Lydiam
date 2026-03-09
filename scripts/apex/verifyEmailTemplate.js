const fs = require('fs');
const html = fs.readFileSync('C:/SFDC_Projects/Lydiam/force-app/main/default/email/unfiled$public/Welcome_Email_Template_1756819238885.email', 'utf-8');

const checks = [
  { label: 'Dear {{RecipientName}} in body', pass: html.includes('Dear {{RecipientName}}') },
  { label: '{{RecipientName}} appears 2+ times', pass: (html.match(/{{RecipientName}}/g) || []).length >= 2 },
  { label: '{{RecipientEmail}} present', pass: html.includes('{{RecipientEmail}}') },
  { label: '{{ReferenceNumber}} present', pass: html.includes('{{ReferenceNumber}}') },
  { label: '{{ReferenceNumber}}-01 present', pass: html.includes('{{ReferenceNumber}}-01') },
  { label: 'No sample Jane Doe', pass: !html.includes('Jane Doe') },
  { label: 'No sample janedoe email', pass: !html.includes('janedoe@gmail.com') },
  { label: 'No 7867-1XX literal', pass: !html.includes('7867-1XX') },
  { label: 'GitHub images present', pass: html.includes('github.com/georgepanayides/lydiamemails') },
  { label: 'Gradient background URL present', pass: html.includes('Gradient.jpg?raw=true') },
];

checks.forEach(c => console.log((c.pass ? '✓' : '✗') + ' ' + c.label));
