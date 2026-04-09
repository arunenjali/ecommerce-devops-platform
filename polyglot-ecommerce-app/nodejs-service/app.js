const express = require('express');
const app = express();
app.get('/', (req,res)=>res.send('NodeJS Service Running'));
app.listen(3000);