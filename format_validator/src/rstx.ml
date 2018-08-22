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

let from_tx (tx : Tx.t) = 
		let rstxin = List.map In.from_in tx.txin
		and	rstout = List.map Out.from_out tx.txout in
					{
						hash = tx.hash;
						txin = rstxin;
						txout = rstout;
			};;

let parse bdata = let tx_opt = Tx.parse bdata in
	match tx_opt with
		| None -> None
		| Some tx -> Some (from_tx tx);; 

let get_in_formats (tx : t) : Rsscript.In_format.t list =
	let get_format (x : In.t) = x.format in
		List.map get_format tx.txin;;

let get_out_formats(tx : t) : Rsscript.Out_format.t list =
		let get_format (x : Out.t) = x.format in
		List.map get_format tx.txout;;

(* let get_in_ids(tx : t) : (Hash.t list) =
	let get_out_hash (x : In.t) = x.out_hash *)

let get_merkleroot_in (tx : t) : Hash.t = 
	let txids_in : (Hash.t list) = (List.map (function (x : In.t) -> x.out_hash) tx.txin)
	and merklize (s : string) (s_new : string) =
		Hash.dsha256 (s ^ s_new) in
		List.fold_left merklize "0" txids_in;;

let get_proof (rstx : t) = let rec iter (b : bytes) (ol : Rsscript.Out_format.t list) =
	match b, ol with
		| b, [] -> b
		| b, (Rsscript.Out_format.Topreturn b_new) :: xs -> iter(b_new ^ b) (xs)
		| b, _ :: xs -> iter b xs in
			iter "" (get_out_formats rstx);;

let in_profile(rstx : t) = let preprofile (txin : In.t) = 
	match txin.format with 
		| Rsscript.In_format.Tid _ -> (1, 0, 0)
		| Rsscript.In_format.Tidquantity _ -> (0, 1, 0)
		| _ -> (0, 0, 1) and
		add (x, y, z) (a, b, c) = (x+a, y+b, z+c) in
			let sigs = List.map preprofile rstx.txin in
				List.fold_left add (0, 0, 0) sigs;;

let out_profile(rstx : t) = let preprofile (txout : Out.t) = 
	match txout.format with 
		| Rsscript.Out_format.Tid _ -> (1, 0, 0, 0)
		| Rsscript.Out_format.Tidquantity _ -> (0, 1, 0, 0)
		| Rsscript.Out_format.Topreturn _ -> (0, 0, 1, 0)
		| Rsscript.Out_format.Other -> (0, 0, 0, 1) and
		add (x, y, z, u) (a, b, c, d) = (x+a, y+b, z+c, u+d) in
			let sigs = List.map preprofile rstx.txout in
				List.fold_left add (0, 0, 0, 0) sigs;;		

let get_format(rstx : t) : format =
		let dect_format = 
		match in_profile rstx, out_profile rstx with
			| (0, 0, _), (0, 0, 1, 1) -> let _ = Printf.printf "Genesis with \n" in Genesis
			| (0, 0, 1), (a, b, 1, _) 
				 when a >= 1 && b >= 1 -> let _ = Printf.printf "Fminting with \n" in Fminting 
			| (1, 0, _), (a, b, 1, _) 
				when (a = 0 || a = 1) && b >= 1 -> let _ = Printf.printf "Minting with \n" in Minting
			| (0, y, _), (0, _, 1, _) 
				when y >= 1 -> let _ = Printf.printf "Ownership with \n" in Ownership
			| _, _ -> let _ = Printf.printf "Other with \n" in Other in
				(* Verbose printing here *)
				let _ = match (in_profile rstx) with
				| (a, b, c) -> Printf.printf "Input Profile: %i %i %i \n" a b c 
				and _ = match (out_profile rstx) with
				| (a, b, c, d) -> Printf.printf "Output Profile: %i %i %i %i \n" a b c d in
					dect_format;;

let validate_fminting(rstx : t) : bool =
	let pred_msig (x : In.t) : bool = match x.format with 
		| Rsscript.In_format.Other -> true
		| _ -> false
		and 
		pred_mpk (x : Out.t) : bool = match x.format with
		| Rsscript.Out_format.Tid _ -> true
		| _ -> false
		and pred_assert (x: Out.t) : bool = match x.format with
		| Rsscript.Out_format.Tidquantity _ -> true
		| _ -> false in
			let mint_sig_outhash_eq (x : Out.t) = 
				let mint_sig_outhash = (List.find pred_msig rstx.txin).out_hash
				and xhash_opt = Rsscript.Out_format.get_id x.format in
					(Some mint_sig_outhash = xhash_opt)
			and mint_pk = (List.find pred_mpk rstx.txout) in
				(mint_sig_outhash_eq mint_pk) && 					
					List.for_all mint_sig_outhash_eq (List.filter pred_assert rstx.txout);;

let validate_minting(rstx : t) : bool =
	let pred_msig_form (x : In.t) : bool = match x.format with 
		| Rsscript.In_format.Tid _ -> true
		| _ -> false
		and 
		pred_mpk_form (x : Out.t) : bool = match x.format with
		| Rsscript.Out_format.Tid _ -> true
		| _ -> false
		and pred_assert_form (x: Out.t) : bool = match x.format with
		| Rsscript.Out_format.Tidquantity _ -> true
		| _ -> false in
			let mint_sig_form = (List.find pred_msig_form rstx.txin).format
			and mint_pk_form = (List.find pred_mpk_form rstx.txout).format in
				(Rsscript.is_equal_id mint_sig_form mint_pk_form) && 					
					List.for_all (function (x: Out.t) -> Rsscript.is_equal_id mint_sig_form x.format) (List.filter pred_assert_form rstx.txout);;

let validate_ownership(rstx : t) : bool = 
		let pred_revoke (x : Rsscript.In_format.t) : bool = match x with
		| Rsscript.In_format.Tidquantity _ -> true
		| _ -> false 
		and pred_assert (x : Rsscript.Out_format.t) : bool = match x with
		| Rsscript.Out_format.Tidquantity _ -> true
		| _ -> false in
			let revoke_forms =  (List.find_all pred_revoke  (get_in_formats rstx))
			and assert_forms =  (List.find_all pred_assert (get_out_formats rstx)) in
				let sorted_rforms = 
					let compare_in (rform_a : Rsscript.In_format.t) (rform_b  : Rsscript.In_format.t) = 
						match (Rsscript.In_format.get_id rform_a), (Rsscript.In_format.get_id rform_b) with
						| Some x, Some y -> String.compare x y
						| _ -> 0 in
							List.sort compare_in revoke_forms
				and sorted_aforms = 
					let compare_out (rform_a : Rsscript.Out_format.t) (rform_b  : Rsscript.Out_format.t) = 
						match (Rsscript.Out_format.get_id rform_a), (Rsscript.Out_format.get_id rform_b) with
						| Some x, Some y -> String.compare x y
						| _ -> 0 in
							List.sort compare_out assert_forms in
					let tally_in (current : (Hash.t*uint8) list) (new_rsform : Rsscript.In_format.t) =
						match Rsscript.In_format.get_id new_rsform, Rsscript.In_format.get_quantity new_rsform with
							| Some new_id, Some new_quantity ->
							(match current with
								| [] -> [(new_id, new_quantity)]
								| (current_id, current_tally) :: rest -> 
									if current_id = new_id then
										(current_id, (Uint8.add current_tally new_quantity)) :: rest
									else
										(current_id, current_tally) :: rest)
							| _ -> [("", Uint8.zero)]
					and tally_out (current : (Hash.t*uint8) list) (new_asform : Rsscript.Out_format.t) =
						match Rsscript.Out_format.get_id new_asform, Rsscript.Out_format.get_quantity new_asform with
							| Some new_id, Some new_quantity ->
							(match current with
								| [] -> [(new_id, new_quantity)]
								| (current_id, current_tally) :: rest -> 
									if current_id = new_id then
										(current_id, Uint8.add current_tally new_quantity) :: rest
									else
										(current_id, current_tally) :: rest)
							| _ -> [("", Uint8.zero)] in 
						let profile_in = List.fold_left tally_in [] sorted_rforms
						and profile_out = List.fold_left tally_out [] sorted_aforms in

							let _ = List.iter (function (id, quant) ->
								Printf.printf "Current In: %s %i \n" id (Uint8.to_int quant)) profile_in in
							
							(profile_in = profile_out)

let validate_format (rstx : t) : bool =
	match get_format(rstx) with
		| Genesis -> true
		| Fminting -> validate_fminting(rstx)
		| Minting -> validate_minting(rstx)
		| Ownership -> validate_ownership(rstx)
		| Other -> false;;

let check_inclusion (path : Hash.t list) (merkleroots : Hash.t list) = 
	let getmerkleroot hashl =
	let rec mround hs = match hs with
	| x' :: [] -> [Hash.dsha256 (x' ^ x')]
	| x' :: x'' :: hs' -> Hash.dsha256 (x' ^ x'') :: mround hs'
	| [] -> []
	in
	let rec m hs = match List.length hs with
		| 0 -> Hash.of_bin @@ Hash.dsha256 (Hash.to_bin Hash.zero)
		| 1 -> Hash.of_bin (List.hd hs)
		| _ -> m @@ mround hs
	in 
	List.map (fun h -> Hash.to_bin h) hashl |> m in
		(List.mem (getmerkleroot path) merkleroots);;