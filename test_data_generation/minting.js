var bch = require('@owstack/bch-lib')
var Script = require('@owstack/bch-lib/lib/script/script');
var Input = require('@owstack/bch-lib/lib/transaction/input/input');
var Output = require('@owstack/bch-lib/lib/transaction/output');

var privateKey = new bch.PrivateKey('L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy');

var raw_assert_script = new Buffer('28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986000000000000000088', 'hex');
var s_assert = Script(raw_assert_script);

var raw_mint_pk = new Buffer('20115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e30898688', 'Hex');
var s_mint_pk = Script(raw_mint_pk)

var raw_mint_sig = new Buffer('20115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986', 'Hex');
var s_mint_sig = Script(raw_mint_sig);

var transaction = new bch.Transaction()
    .uncheckedAddInput(new Input({
        prevTxId: "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
        outputIndex: 0,
        sequencenumber: 0,
        script: s_mint_sig
    }))
    .addOutput(new Output({
        script: s_mint_pk,
        satoshis: 5
    }))
    .addOutput(new Output({
        script: s_assert,
        satoshis: 5
    }))
    .addData('Proof');

console.log(transaction.toString());