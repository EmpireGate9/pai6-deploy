const express = require('express');
const app = express();
app.use(express.json());
app.get('/health', (req,res)=>res.json({status:'ok'}));
app.get('/api/info', (req,res)=>res.json({service:'pai6-core', version:'v1'}));
app.listen(process.env.PORT||8080, ()=>console.log('Pai6 core running'));