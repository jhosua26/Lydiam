const fs = require('fs');

// Read the processed HTML
const html = fs.readFileSync('C:/SFDC_Projects/Lydiam/force-app/main/default/email/unfiled$public/Welcome_Email_Template_1756819238885.email', 'utf-8');

// Build the sf api request rest --file format
const requestFile = {
  url: "services/data/v65.0/sobjects/EmailTemplate/00XKB000000lSyM2AU",
  method: "PATCH",
  body: {
    mode: "raw",
    raw: {
      HtmlValue: html
    }
  }
};

const outPath = 'C:/SFDC_Projects/Lydiam/scripts/apex/restRequest.json';
fs.writeFileSync(outPath, JSON.stringify(requestFile), 'utf-8');
console.log('REST request file written: ' + (fs.statSync(outPath).size / 1024).toFixed(1) + ' KB');
