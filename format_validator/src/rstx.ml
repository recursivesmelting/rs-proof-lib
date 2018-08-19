open Stdint;;

module In = struct
	type t = {
		out_hash			: string;
		out_n				: uint32;
		format				: Rsscript.In_format.t;
		sequence			: uint32;
	};;

	let from_in (x : Tx.In.t) = 
		let y, _ = x.script in
		{
			out_hash = x.out_hash;
			out_n = x.out_n;
			format = Rsscript.In_format.parse y;
			sequence = x.sequence;
		};;
end

module Out = struct
	type t = {
		value	: int64;
		format	: Rsscript.Out_format.t;
	};;

	let from_out (x : Tx.Out.t) = 
		let y, _ = x.script in
		{
			value = x.value;
			format = Rsscript.Out_format.parse y;
		};;
end

type t = {
	hash		: Hash.t;
	txin 		: In.t list;
	txout 		: Out.t list;
};;

type format = Genesis | Ownership | Fminting | Minting | Other;;

let from_tx (tx_opt : Tx.t option) = match tx_opt with 
	| Some tx ->
		let rstxin = List.map In.from_in tx.txin in
		let	rstout = List.map Out.from_out tx.txout in
			Some {
				hash = tx.hash;
				txin = rstxin;
				txout= rstout;
			}
	| None -> None;;

let get_in_formats (tx : t) : Rsscript.In_format.t list =
	let get_format (x : In.t) = x.format in
		List.map get_format tx.txin;;

let get_out_formats(tx : t) : Rsscript.Out_format.t list =
		let get_format (x : Out.t) = x.format in
		List.map get_format tx.txout;;

let in_signature(rstx : t) = let presignature (txin : In.t) = 
	match txin.format with 
		| Rsscript.In_format.Tid _ -> (1, 0, 0)
		| Rsscript.In_format.Tidquantity _ -> (0, 1, 0)
		| _ -> (0, 0, 1) and
		add (x, y, z) (a, b, c) = (x+a, y+b, z+c) in
			let sigs = List.map presignature rstx.txin in
				List.fold_left add (0, 0, 0) sigs;;

let out_signature(rstx : t) = let presignature (txout : Out.t) = 
	match txout.format with 
		| Rsscript.Out_format.Tid _ -> (1, 0, 0, 0)
		| Rsscript.Out_format.Tidquantity _ -> (0, 1, 0, 0)
		| Rsscript.Out_format.Topreturn _ -> (0, 0, 1, 0)
		| Rsscript.Out_format.Other -> (0, 0, 0, 1) and
		add (x, y, z, u) (a, b, c, d) = (x+a, y+b, z+c, u+d) in
			let sigs = List.map presignature rstx.txout in
				List.fold_left add (0, 0, 0, 0) sigs;;		

let get_format(rstx_opt : t option) : format option = match rstx_opt with
	| Some rstx ->
		let dect_format = match in_signature rstx, out_signature rstx with
			| (0, 0, _), (0, 0, 1, 1) -> Genesis
			| (0, 0, 1), (a, b, 1, _) 
				when (a = 0 || a = 1) && b >= 1 -> Fminting
			| (1, 0, _), (a, b, 1, _) 
				when (a = 0 || a = 1) && b >= 1 -> Minting
			| (0, y, _), (0, _, 1, _) 
				when y >= 1 -> Ownership
			| _ -> Other in
				Some dect_format
	| None -> None;;

let check_fminting(rstx : t) : bool =
	let pred_in (x : In.t) : bool = match x.format with 
		| Rsscript.In_format.Other -> true
		| _ -> false
		and 
		pred_out (x : Out.t) : bool = match x.format with
		| Rsscript.Out_format.Tid _ -> true
		| _ -> false in
			let rsscript_in_hash = (List.find pred_in rstx.txin).out_hash
			and rsscript_out_form = (List.find pred_out rstx.txout).format in
				(Some rsscript_in_hash) = (Rsscript.Out_format.get_id rsscript_out_form);;

let check_minting(rstx : t) : bool =
	let pred_in (x : In.t) : bool = match x.format with 
		| Rsscript.In_format.Tid _ -> true
		| _ -> false
		and 
		pred_out (x : Out.t) : bool = match x.format with
		| Rsscript.Out_format.Tid _ -> true
		| _ -> false in
			let rsscript_in_form = (List.find pred_in rstx.txin).format
			and rsscript_out_form = (List.find pred_out rstx.txout).format in
				(Rsscript.is_equal_id rsscript_in_form rsscript_out_form);;
			
let check_ownership(rstx : t) : bool =
	let sum_in = 
		let add (s1 : Rsscript.In_format.t) (s2 : Rsscript.In_format.t) = match s1, s2 with
			| Rsscript.In_format.Tidquantity {iq_token_id = tid1; token_quantity = x;},
			Rsscript.In_format.Tidquantity {iq_token_id = tid2; token_quantity = y;}
			when tid1 = tid2
				-> Rsscript.In_format.Tidquantity {iq_token_id = tid2; token_quantity = Uint8.(x + y);}
			| _ -> s2
			in
				let rec sum_fold (unique : Rsscript.In_format.t list) (dups : Rsscript.In_format.t list) = match dups with
				| [] -> unique
				| x :: xs -> 					
						if (List.exists (Rsscript.is_equal_id_in x) unique) then
							sum_fold (List.map (add x) unique) dups
						else
							if (match x with | Rsscript.In_format.Tidquantity _ -> true | _ -> false) then
								sum_fold (x::unique) xs
							else
								sum_fold (unique) xs in
									sum_fold [] (get_in_formats rstx)
		and sum_out = 
			let add (s1 : Rsscript.Out_format.t) (s2 : Rsscript.Out_format.t) = match s1, s2 with
				| Rsscript.Out_format.Tidquantity {iq_token_id = tid1; token_quantity = x;},
				Rsscript.Out_format.Tidquantity {iq_token_id = tid2; token_quantity = y;}
				when tid1 = tid2
					-> Rsscript.Out_format.Tidquantity {iq_token_id = tid2; token_quantity = Uint8.(x + y);}
				| _ -> s2
				in
					let rec sum_fold (unique : Rsscript.Out_format.t list) (dups : Rsscript.Out_format.t list) = match dups with
					| [] -> unique
					| x :: xs ->
							if (List.exists (Rsscript.is_equal_id_out x) unique) then
								sum_fold (List.map (add x) unique) dups
							else
								if (match x with | Rsscript.Out_format.Tidquantity _ -> true | _ -> false) then
									sum_fold (x::unique) xs
								else
									sum_fold unique xs in
										sum_fold [] (get_out_formats rstx)
			in let rec check output = match output with
				| x :: xs -> 
					if List.exists (fun y -> (Rsscript.is_equal y x)) sum_in then
						check xs
					else
						false
				| [] -> true in
					(check sum_out);;

let check_format(rstx_opt : t option) : bool =
	let format = get_format(rstx_opt) in
		match rstx_opt with 
			| Some rstx -> let valid =
				match format with
					| Some Genesis -> true
					| Some Fminting -> check_fminting(rstx)
					| Some Minting -> check_minting(rstx)
					| Some Ownership -> check_ownership(rstx)
					| Some Other -> false
					| None -> false in 
					valid
			| None -> false;;

let parse data = from_tx (Tx.parse data);;
 

(* let%test _ = (parse (Bytes.of_string "01000000018689302ea03ef5dd56fb7940a867f9240fa811eddeb0fa4c87ad9ff3728f5e11000000006b483045022100bc4295d369443e2cc4e20b50a6fd8e7e16c08aabdbb42bdf167dec9d41afc3d402207a8e0ccb91438785e51203e7d2f85c4698ff81245936ebb71935e3d052876dcd4121029f50f51d63b345039a290c94bffd3180c99ed659ff6ea6b1242bca47eb93b59fffffffff01983a0000000000001976a914ad618cf4333b3b248f9744e8e81db2964d0ae39788ac00000000") = None);; *)