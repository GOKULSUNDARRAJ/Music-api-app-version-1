const https = require('https');

https.get('https://music-app-api-1.onrender.com/api/user/collaborative-playlist/cpl_001/members', (res) => {
  console.log('Members endpoint status:', res.statusCode);
}).on('error', (e) => {
  console.error(e);
});
