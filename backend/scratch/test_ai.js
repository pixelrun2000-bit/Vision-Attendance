const axios = require('axios');
async function test() {
  try {
    const res = await axios.get('http://localhost:5000/api/v1/health');
    console.log('AI Health:', res.data);
  } catch (err) {
    console.error('AI Health Check Failed:', err.message);
  }
}
test();
