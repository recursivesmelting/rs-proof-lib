var bch = require('@owstack/bch-lib')
var Script = require('@owstack/bch-lib/lib/script/script');
var Output = require('@owstack/bch-lib/lib/transaction/output');

var raw_assert_script = new Buffer('28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986000000000000000088', 'hex');
var s_assert = Script(raw_assert_script);

var raw_mint_pk = new Buffer('20115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e30898688', 'Hex');
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
  .addOutput(new Output({
    script: s_mint_pk,
    satoshis: 5
  }))
  .addOutput(new Output({
    script: s_assert,
    satoshis: 5
  }))
  .addData('Proof')
  .sign(privateKey);

console.log(transaction.toString());