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
	let format = Rstx.get_format (Rstx.from_tx (Tx.parse (Hex.to_string raw))) in
	match format with
	| None -> assert_equal true false
	| Some _ -> 
		assert_equal (format) (form_dec)


let suite = 
	"format_validation" >::: [
	"Parse Mint Pubkey Script" 			>:: rs_script_out_parse_test (`Hex "202c82810e17b4d28d856018b3f0130253e1e77ae51e2a76dd83e8eba6889988fc88")
		("Identity");
	"Parse Mint Sig Script" 			>:: rs_script_in_parse_test (`Hex "8788202c82810e17b4d28d856018b3f0130253e1e77ae51e2a76dd83e8eba6889988fc")
		("Identity");
	"Parse Assert Script" 				>:: rs_script_out_parse_test (`Hex "289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e38887")
		("IdentityQuantity");
	"Parse Revoke Script" 				>:: rs_script_in_parse_test (`Hex "88289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e3")
		("IdentityQuantity");
	"Parse Genesis TX"					>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006a47304402200ecd817422fa4a9d77d9e44357e0b6548547dc88fef223881e0f07c74223e85a022007146a314cabbad0874b7d1e88393a920a3aa8171eacfccee91ebf84c9c18ea94121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff0205000000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac0000000000000000076a0550726f6f6600000000")
		(Some Genesis); 
	"Parse Ownership TX"				>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000002a88289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e3ffffffff0205000000000000002b289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e388870000000000000000076a0550726f6f6600000000")
		(Some Ownership); 
	"Parse FMinting TX"				>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006a4730440220419a445b3864420a58f2cd19fd09417739f03c3354058fd09d8cce87aa80825e0220010e690ca55a0f5e30dac4dc143d0fcbc429b6618722135817d77f147c088d514121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff0405000000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac05000000000000002b289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e38887050000000000000022202c82810e17b4d28d856018b3f0130253e1e77ae51e2a76dd83e8eba6889988fc880000000000000000066a044461746100000000")
		(Some Fminting);
	"Parse Minting TX"				>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e1100000000238788202c82810e17b4d28d856018b3f0130253e1e77ae51e2a76dd83e8eba6889988fcffffffff0305000000000000002b289b2842b00b43a4058ca98abd5d5cefdc49394ebf7d024358d9646513e9c8308ed46971b32eb1c0e38887050000000000000022202c82810e17b4d28d856018b3f0130253e1e77ae51e2a76dd83e8eba6889988fc880000000000000000076a0550726f6f6600000000")
		(Some Minting);
	"Parse Non-RS TX"					>:: tx_format_parse_test
		(`Hex "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006b483045022100bc4295d369443e2cc4e20b50a6fd8e7e16c08aabdbb42bdf167dec9d41afc3d402207a8e0ccb91438785e51203e7d2f85c4698ff81245936ebb71935e3d052876dcd4121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff01983a0000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac00000000")
		(Some Other);
];;

let () = run_test_tt_main suite;;