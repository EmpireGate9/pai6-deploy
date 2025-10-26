const express = require('express');
const fs = require('fs');
const router = express.Router();
const cfgPath = __dirname + '/../config/dynamic_config.json';
router.get('/admin/config', (req,res)=>{ try{ const cfg = fs.readFileSync(cfgPath); res.setHeader('Content-Type','application/json'); res.send(cfg);}catch(e){res.status(500).send({error:'config missing'})}});
module.exports = router;
