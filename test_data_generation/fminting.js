var bch = require('@owstack/bch-lib')
var Script = require('@owstack/bch-lib/lib/script/script');
var Output = require('@owstack/bch-lib/lib/transaction/output');

var raw_assert_script = new Buffer('202c82810e17b4d28d856018b3f0130253e1e77ae51e2a76dd83e8eba6889988fc88', 'hex');
var s_assert = Script(raw_assert_script);

var raw_mint_pk = new Buffer('289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e38887', 'Hex');
var s_mint_pk = Script(raw_mint_pk)

var privateKey = new bch.PrivateKey('L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy');
var utxo = {
  "txId": "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
  "outputIndex": 0,
  "address": "17XBj6iFEsf8kzDMGQk5ghZipxX49VXuaV",
  "script": "76a91447862fe165e6121af80d5dde1ecb478ed170565b88ac",
  "satoshis": 10
};

var transaction = new bch.Transaction()
  .from(utxo)
  .to('1Gokm82v6DmtwKEB8AiVhm82hyFSsEvBDK', 5)
  .addOutput(new Output({
    script: s_mint_pk,
    satoshis: 5
  }))
  .addOutput(new Output({
    script: s_assert,
    satoshis: 5
  }))
  .addData('Data')
  .sign(privateKey);

console.log(transaction.toString());