async function test() {
  try {
    const res = await fetch('https://music-app-api-1.onrender.com/api/user/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userEmail: 'test_admin_remove@example.com', userPassword: 'password123' })
    });
    const data = await res.json();
    const token = data.response.access_token;
    
    const memRes = await fetch('https://music-app-api-1.onrender.com/api/user/collaborative-playlist/cpl_001/members', {
      headers: { 'Authorization': 'Bearer ' + token }
    });
    console.log('Status:', memRes.status);
    const memData = await memRes.text();
    console.log('Body:', memData);
  } catch(e) {
    console.error(e);
  }
}
test();
