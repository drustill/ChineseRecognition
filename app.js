const express = require('express');
const pinyinify = require('hanzi-tools').pinyinify;

const app = express();

// Define a route that calls the pinyin function
app.get('/api/pinyin/:text', (req, res) => {
  const text = req.params.text;
  const result = pinyinify(text, false);
  res.send(result);
});

app.get('/', (res) => {
  res.send("HelloPinyinAPI World");
})

// Start the server
app.listen(process.env.PORT || 8080, () => {
  console.log('API listening on port 8080');
});