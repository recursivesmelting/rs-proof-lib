open Stdint;;
open Bitstring;;
open Varint;;

module In = struct
	type t = {
		out_hash			: string;
		out_n				: uint32;
		script				: Script.t;
		sequence			: uint32;
	};;

	let parse bdata =
		match%bitstring bdata with
		| {|
			out_hash	: 32*8: string;
			out_n		: 32 : littleendian;
			rest		: -1 : bitstring
		|} ->
			let sclen, rest' = parse_varint rest in
			match%bitstring rest' with
			| {|
				script 		: Uint64.to_int (sclen) * 8 : string;
				sequence	: 32 : littleendian;
				rest'		: -1 : bitstring
			|} ->
				(rest', Some ({
					out_hash = Hash.of_bin out_hash;
					out_n = Uint32.of_int32 out_n;
					script = Script.parse script;
					sequence = Uint32.of_int32 sequence;
					}))

		| {| _ |} -> (bitstring_of_string "", None)
	;;

	let parse_all data =
		let inlen, rest' = parse_varint data in
		let rec parse_all' n d acc = match n with
		| 0 -> (d, Some (acc))
		| n ->
			let rest, txin = parse d in
			match txin with
			| None -> (bitstring_of_string "", None)
			| Some (txin) -> parse_all' (n-1) rest (txin::acc)
		in parse_all' (Uint64.to_int inlen) rest' []
	;;
end

module Out = struct
	type t = {
		value	: int64;
		script	: Script.t;
	};;

	let parse bdata =
		match%bitstring bdata with
		| {|
			value		: 64 : littleendian;
			rest		: -1 : bitstring
		|} ->
			let sclen, rest' = parse_varint rest in
			match%bitstring rest' with
			| {|
				script 		: Uint64.to_int (sclen) * 8 : string;
				rest''		: -1 : bitstring
			|} ->
			let sc = Script.parse script in
			(rest'', Some ({value = value; script = sc; }))
		| {| _ |} -> (bitstring_of_string "", None)
	;;

	let parse_all data =
		let outlen, rest' = parse_varint data in
		let rec parse_all' n d acc = match n with
		| 0 -> (d, Some (acc))
		| n ->
			let rest, txout = parse d in
			match txout with
			| None -> (bitstring_of_string "", None)
			| Some (txout) -> parse_all' (n-1) rest (txout::acc)
		in parse_all' (Uint64.to_int outlen) rest' []
	;;
end

type t = {
	hash		: Hash.t;
	txin 		: In.t list;
	txout 		: Out.t list;
};;

let parse data =
	let bdata = bitstring_of_string data in
	match%bitstring bdata with
	| {|
		_		: 32 : littleendian;
		rest		: -1 : bitstring
	|} ->
		let rest', txin = In.parse_all rest in
		let rest'', txout = Out.parse_all rest' in
		match (txin, txout) with
		| None, _ -> None
		| _, None -> None
		| Some (txin), Some (txout) ->
			let bdata = rest'' in
			match%bitstring bdata with
			| {|
				_	: 32 : littleendian;
				rest		: -1 : bitstring
			|} -> 
				let rest''' = string_of_bitstring rest in
				let txhash = Hash.of_bin (Hash.hash256 (Bytes.sub data 0 (Bytes.length data))) in
				if (Bytes.length rest''') = 0 then
					Some ({
						hash	= txhash;
						txin	= List.rev txin;
						txout	= List.rev txout;
					})
				else
					None
			| {| _ |} -> None
;;