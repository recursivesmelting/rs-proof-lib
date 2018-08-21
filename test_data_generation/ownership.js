var bch = require('@owstack/bch-lib')
var Script = require('@owstack/bch-lib/lib/script/script');
var Input = require('@owstack/bch-lib/lib/transaction/input/input');
var Output = require('@owstack/bch-lib/lib/transaction/output');

var raw_assert_script = new Buffer('28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986000000000000000188', 'hex');
var s_assert = Script(raw_assert_script);

var raw_assert_script_2 = new Buffer('28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986000000000000000288', 'hex');
var s_assert_2 = Script(raw_assert_script_2);

var raw_revoke_script = new Buffer('28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000001', 'Hex');
var s_revoke = Script(raw_revoke_script);

var transaction = new bch.Transaction()
    .uncheckedAddInput(new Input({
        prevTxId: "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
        outputIndex: 0,
        sequencenumber: 0,
        script: s_revoke
    }))
    .uncheckedAddInput(new Input({
        prevTxId: "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
        outputIndex: 0,
        sequencenumber: 0,
        script: s_revoke
    }))
    .uncheckedAddInput(new Input({
        prevTxId: "115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986",
        outputIndex: 0,
        sequencenumber: 0,
        script: s_revoke
    }))
    .addOutput(new Output({
        script: s_assert,
        satoshis: 5
    }))
    .addOutput(new Output({
        script: s_assert_2,
        satoshis: 5
    }))
    .addData('Proof');

console.log(transaction.toString());