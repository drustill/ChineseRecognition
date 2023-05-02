const express = require('express');
const pinyinify = require('hanzi-tools').pinyinify;

const app = express();

// Define a route that calls the pinyin function
app.get('/api/pinyin/:text', (req, res) => {
  const text = req.params.text;
  const result = pinyinify(text, false);
  res.send(result);
});

// Start the server
app.listen(3000, () => {
  console.log('API listening on port 3000');
});