const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const path = require('path');

async function testRecognize() {
  const imagePath = path.join(__dirname, '../uploads/profiles/user_44_enroll_1778745551324.jpg');
  if (!fs.existsSync(imagePath)) {
    console.error('Test image not found:', imagePath);
    return;
  }

  const form = new FormData();
  form.append('image', fs.createReadStream(imagePath));

  try {
    console.log('Testing Python AI Recognize...');
    const res = await axios.post('http://localhost:5000/api/v1/recognize', form, {
      headers: form.getHeaders(),
    });
    console.log('AI Result:', JSON.stringify(res.data, null, 2));
  } catch (err) {
    console.error('AI Request Failed:', err.response ? err.response.data : err.message);
  }
}

testRecognize();
