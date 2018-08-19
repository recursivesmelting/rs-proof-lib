var bchLib = require('@owstack/bch-lib')
var Script = require('@owstack/bch-lib/lib/script/script');
var Output = require('@owstack/bch-lib/lib/transaction/output');
var Input = require('@owstack/bch-lib/lib/transaction/input/input');


var privateKey = new bchLib.PrivateKey('L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy');

  var raw_assert_script = new Buffer('289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e38887', 'hex');
  var s_assert = Script(raw_assert_script);

  var raw_revoke_script = new Buffer('88289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e3', 'Hex');
  var s_revoke = Script(raw_revoke_script);
  var transaction = new bchLib.Transaction()
  .uncheckedAddInput(new Input({
    prevTxId: "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
    outputIndex: 0,
    sequencenumber:0,
    script : s_revoke
  }))
  .addOutput(new Output({
    script: s_assert,
    satoshis: 5
  }))
  .addData('PROOF');

  console.log(transaction.toString());