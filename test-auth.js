const https = require('https');

const data = JSON.stringify({
  userEmail: 'test_admin_remove@example.com',
  userPassword: 'password123',
  userName: 'TestAdmin',
  userMobile: '1234567890'
});

const options = {
  hostname: 'music-app-api-1.onrender.com',
  port: 443,
  path: '/api/user/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('Register:', body);
    const result = JSON.parse(body);
    const token = result.token;
    
    if (token) {
      https.get('https://music-app-api-1.onrender.com/api/user/collaborative-playlist/cpl_001/members', {
        headers: { 'Authorization': 'Bearer ' + token }
      }, (res2) => {
        let body2 = '';
        res2.on('data', d => body2 += d);
        res2.on('end', () => console.log('Members:', res2.statusCode, body2));
      });
    } else {
      // maybe already registered, try login
      const loginData = JSON.stringify({ userEmail: 'test_admin_remove@example.com', userPassword: 'password123' });
      const loginReq = https.request({
        hostname: 'music-app-api-1.onrender.com',
        port: 443,
        path: '/api/user/login',
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': loginData.length }
      }, (res3) => {
        let body3 = '';
        res3.on('data', d => body3 += d);
        res3.on('end', () => {
          console.log('Login:', body3);
          const t = JSON.parse(body3).token;
          if (t) {
            https.get('https://music-app-api-1.onrender.com/api/user/collaborative-playlist/cpl_001/members', {
              headers: { 'Authorization': 'Bearer ' + t }
            }, (res4) => {
              let body4 = '';
              res4.on('data', d => body4 += d);
              res4.on('end', () => console.log('Members:', res4.statusCode, body4));
            });
          }
        });
      });
      loginReq.write(loginData);
      loginReq.end();
    }
  });
});

req.on('error', console.error);
req.write(data);
req.end();
