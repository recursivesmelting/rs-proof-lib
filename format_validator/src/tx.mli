open Stdint
open Bitstring

module In : sig
	type t = {
		out_hash			: string;
		out_n				: uint32;
		script				: Script.t;
		sequence			: uint32;
	}

	val parse 			: bitstring -> bitstring * t option
	val parse_all		: bitstring -> bitstring * t list option
end

module Out : sig
	type t = {
		value	: int64;
		script	: Script.t;
	}

	val parse			: bitstring -> bitstring * t option
	val parse_all		: bitstring -> bitstring * t list option
end

type t = {
	hash		: Hash.t;
	txin 		: In.t list;
	txout 		: Out.t list;
}

val parse 						: bytes -> t option