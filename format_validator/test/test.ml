open Format_validator;;
open Stdint;;
open OUnit2;;

let varint_parse_test bl res _ =
	let v1 = Varint.parse_varint (Bitstring.bitstring_of_string (Hex.to_string bl)) in
	assert_equal (fst v1) (Uint64.of_int res)
;;

let script_parse_test sc scdec _ =
	let s = Script.parse (Hex.to_string sc) in
	assert_equal (fst s) (fst scdec)
;;

let rs_script_in_parse_test sc scdec _ =
	let s, _ = Script.parse (Hex.to_string sc) in 
		let y = Rsscript.In_format.parse s in
			let get_type = function
			| Rsscript.In_format.Tid _ -> "Identity"
			| Rsscript.In_format.Tidquantity _ -> "IdentityQuantity"
			| _ -> "NA"
			in
				assert_equal (get_type y) (scdec);;

let rs_script_out_parse_test sc scdec _ =
	let s, _ = Script.parse (Hex.to_string sc) in 
		let y = Rsscript.Out_format.parse s in
			let get_type = function
			| Rsscript.Out_format.Tid _ -> "Identity"
			| Rsscript.Out_format.Tidquantity _ -> "IdentityQuantity"
			| Rsscript.Out_format.Topreturn _ -> "Return"
			| _ -> "NA"
			in
				assert_equal (get_type y) (scdec);;

let tx_format_parse_test raw form_dec _ =
	let tx_opt = Tx.parse (Hex.to_string raw) in
	match tx_opt with
		| None -> assert_equal true false
		| Some tx -> let format = Rstx.get_format (Rstx.from_tx tx) in
			assert_equal (format) (form_dec);;

let tx_validate_format_parse_test raw validate_dec _ =
	let tx_opt = Tx.parse (Hex.to_string raw) in
	match tx_opt with
		| None -> assert_equal true false
		| Some tx -> let check = Rstx.validate_format (Rstx.from_tx (tx)) in
		assert_equal (check) (validate_dec);;

let suite = 
	"format_validation" >::: [
	"Parse Mint Pubkey Script" 			>:: rs_script_out_parse_test (`Hex "20115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e30898688")
		("Identity");
	"Parse Mint Sig Script" 			>:: rs_script_in_parse_test (`Hex "20115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986")
		("Identity");
	"Parse Assert Script" 				>:: rs_script_out_parse_test (`Hex "28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986000000000000000088")
		("IdentityQuantity");
	"Parse Revoke Script" 				>:: rs_script_in_parse_test (`Hex "28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000")
		("IdentityQuantity");
	"Parse Genesis TX"					>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006a47304402200ecd817422fa4a9d77d9e44357e0b6548547dc88fef223881e0f07c74223e85a022007146a314cabbad0874b7d1e88393a920a3aa8171eacfccee91ebf84c9c18ea94121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff0205000000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac0000000000000000076a0550726f6f6600000000")
		(Rstx.Genesis); 
	"Parse Ownership TX"				>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002928115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000ffffffff0205000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000880000000000000000076a0550726f6f6600000000")
		(Ownership);
	"Parse FMinting TX"				>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006b4830450221009003f7f7db16bfc12d461068f6a595605d626c97467171422112b24e9665230402203b247feea2caed48051e6a076d6f1bd97cb89f9e51c4514f6557de41525e0b974121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff0305000000000000002220115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089868805000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000880000000000000000076a0550726f6f6600000000")
		(Rstx.Fminting);	
	"Parse Minting TX"				>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002120115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986ffffffff0305000000000000002220115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089868805000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000880000000000000000076a0550726f6f6600000000")
		(Rstx.Minting);
	"Parse Non-RS TX"					>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006b483045022100bc4295d369443e2cc4e20b50a6fd8e7e16c08aabdbb42bdf167dec9d41afc3d402207a8e0ccb91438785e51203e7d2f85c4698ff81245936ebb71935e3d052876dcd4121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff01983a0000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac00000000")
		(Rstx.Other);
	"Check Genesis TX"					>:: tx_validate_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006a47304402200ecd817422fa4a9d77d9e44357e0b6548547dc88fef223881e0f07c74223e85a022007146a314cabbad0874b7d1e88393a920a3aa8171eacfccee91ebf84c9c18ea94121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff0205000000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac0000000000000000076a0550726f6f6600000000")
		(true); 
	"Check Ownership TX"				>:: tx_validate_format_parse_test
		(`Hex "01000000038689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002928115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000001ffffffff8689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002928115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000001ffffffff8689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002928115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000001ffffffff0305000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e30898600000000000000018805000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000002880000000000000000076a0550726f6f6600000000")
		(true); 
	"Check FMinting TX"				>:: tx_validate_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006b4830450221009003f7f7db16bfc12d461068f6a595605d626c97467171422112b24e9665230402203b247feea2caed48051e6a076d6f1bd97cb89f9e51c4514f6557de41525e0b974121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff0305000000000000002220115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089868805000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000880000000000000000076a0550726f6f6600000000")
		(true); 
	"Check Minting TX"				>:: tx_validate_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002120115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e308986ffffffff0305000000000000002220115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089868805000000000000002a28115e8f72f39fad874cfab0deed11a80f24f967a84079fb56ddf53ea02e3089860000000000000000880000000000000000076a0550726f6f6600000000")
		(true); 
	"Check Non-RS TX"					>:: tx_validate_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006b483045022100bc4295d369443e2cc4e20b50a6fd8e7e16c08aabdbb42bdf167dec9d41afc3d402207a8e0ccb91438785e51203e7d2f85c4698ff81245936ebb71935e3d052876dcd4121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff01983a0000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac00000000")
		(false);
];;

let () = run_test_tt_main suite;;
