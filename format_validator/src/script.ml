type opcode =
(* Constants *)
| OP_0
| OP_FALSE
| OP_DATA of int * bytes
| OP_PUSHDATA1 of int * bytes
| OP_PUSHDATA2 of int * int * bytes
| OP_PUSHDATA4 of int * int * int * int * bytes
| OP_1NEGATE
| OP_1
| OP_TRUE
| OP_2
| OP_3
| OP_4
| OP_5
| OP_6
| OP_7
| OP_8
| OP_9
| OP_10
| OP_11
| OP_12
| OP_13
| OP_14
| OP_15
| OP_16

(* Flow *)
| OP_IF
| OP_NOTIF
| OP_ELSE
| OP_ENDIF
| OP_VERIFY
| OP_RETURN of bytes

(* Stack *)
| OP_TOALTSTACK
| OP_FROMALTSTACK
| OP_IFDUP
| OP_DEPTH
| OP_DROP
| OP_DUP
| OP_NIP
| OP_OVER
| OP_PICK
| OP_ROLL
| OP_ROT
| OP_SWAP
| OP_TUCK
| OP_2DROP
| OP_2DUP
| OP_3DUP
| OP_2OVER
| OP_2ROT
| OP_2SWAP

(* Splice *)
| OP_CAT
| OP_SUBSTR
| OP_LEFT
| OP_RIGHT
| OP_SIZE

(* Bitwise logic *)
| OP_INVERT
| OP_AND
| OP_OR
| OP_XOR
| OP_EQUAL
| OP_EQUALVERIFY

(* Arithmetic*)
| OP_1ADD
| OP_1SUB
| OP_2MUL
| OP_2DIV
| OP_NEGATE
| OP_ABS
| OP_NOT
| OP_0NOTEQUAL
| OP_ADD
| OP_SUB
| OP_MUL
| OP_DIV
| OP_MOD
| OP_LSHIFT
| OP_RSHIFT
| OP_BOOLAND
| OP_BOOLOR
| OP_NUMEQUAL
| OP_NUMEQUALVERIFY
| OP_NUMNOTEQUAL
| OP_LESSTHAN
| OP_GREATERTHAN
| OP_LESSTHANOREQUAL
| OP_GREATERTHANOREQUAL
| OP_MIN
| OP_MAX
| OP_WITHIN

(* Crypto *)
| OP_RIPEMD160
| OP_SHA1
| OP_SHA256
| OP_HASH160
| OP_HASH256
| OP_CODESEPARATOR
| OP_CHECKSIG
| OP_CHECKSIGVERIFY
| OP_CHECKMULTISIG
| OP_CHECKMULTISIGVERIFY

(* Lock time *)
| OP_CHECKLOCKTIMEVERIFY
| OP_CHECKSEQUENCEVERIFY

(* Pseudo words *)
| OP_PUBKEYHASH
| OP_PUBKEY
| OP_INVALIDOPCODE

(* Reserved words*)
| OP_RESERVED
| OP_VER
| OP_VERIF
| OP_VERNOTIF
| OP_RESERVED1
| OP_RESERVED2
| OP_NOP of int;;

type t = opcode list * int;;

let opcode_of_hex s =
    let consume_next s =
        match Bytes.length s with
        | 0 -> failwith "Not enough bytes"
        | 1 -> (Bytes.get s 0 |> Char.code, "")
        | n ->
            let c = Bytes.get s 0 |> Char.code in
            let s' = Bytes.sub s 1 @@ n - 1 in
            (c, s')
    in
    let consume_bytes s sizea =
        let sizea = List.fold_left (fun acc x -> acc * 0xFF + x) 0 sizea in
        if sizea > Bytes.length s then
           (Bytes.sub s 0 (Bytes.length s), "")
        else
           (Bytes.sub s 0 sizea, Bytes.sub s sizea ((Bytes.length s) - sizea))
    in
    let c, s' = consume_next s in
    match Bytes.length s', c with
    (* Constants *)
    | _, 0x00 -> (OP_0, s')
    | _, x when x >= 0x01 && x <= 0x4b ->
        let d, s'' = consume_bytes s' [x] in
        (OP_DATA (x, d), s'')
    | l, 0x4c when l >= 1 ->
        let c', s'' = consume_next s' in
        let d, s'' = consume_bytes s'' [c'] in
        (OP_PUSHDATA1 (c', d), s'')
    | l, 0x4c when l < 1 ->
        (OP_NOP (0x4c), s')
    | l, 0x4d when l >= 2 ->
        let c', s'' = consume_next s' in
        let c'', s'' = consume_next s'' in
        let d, s'' = consume_bytes s'' [c'; c''] in
        (OP_PUSHDATA2 (c', c'', d), s'')
    | l, 0x4d when l < 2 ->
        (OP_NOP (0x4d), s')
    | l, 0x4e when l >= 4 ->
        let c', s'' = consume_next s' in
        let c'', s'' = consume_next s'' in
        let c''', s'' = consume_next s'' in
        let c'''', s'' = consume_next s'' in
        let d, s'' = consume_bytes s'' [c'; c''; c'''; c''''] in
        (OP_PUSHDATA4 (c', c'', c''', c'''', d), s'')
    | l, 0x4e when l < 4 ->
        (OP_NOP (0x4e), s')
    | _, 0x4f -> (OP_1NEGATE, s')
    | _, 0x51 -> (OP_1, s')
    | _, 0x52 -> (OP_2, s')
    | _, 0x53 -> (OP_3, s')
    | _, 0x54 -> (OP_4, s')
    | _, 0x55 -> (OP_5, s')
    | _, 0x56 -> (OP_6, s')
    | _, 0x57 -> (OP_7, s')
    | _, 0x58 -> (OP_8, s')
    | _, 0x59 -> (OP_9, s')
    | _, 0x5a -> (OP_10, s')
    | _, 0x5b -> (OP_11, s')
    | _, 0x5c -> (OP_12, s')
    | _, 0x5d -> (OP_13, s')
    | _, 0x5e -> (OP_14, s')
    | _, 0x5f -> (OP_15, s')
    | _, 0x60 -> (OP_16, s')

    (* Flow *)
    | _, 0x63 -> (OP_IF, s')
    | _, 0x64 -> (OP_NOTIF, s')
    | _, 0x67 -> (OP_ELSE, s')
    | _, 0x68 -> (OP_ENDIF, s')
    | _, 0x69 -> (OP_VERIFY, s')
    | _, 0x6a -> (OP_RETURN (s'), "")

    (* Stack *)
    | _, 0x6b -> (OP_TOALTSTACK, s')
    | _, 0x6c -> (OP_FROMALTSTACK, s')
    | _, 0x73 -> (OP_IFDUP, s')
    | _, 0x74 -> (OP_DEPTH, s')
    | _, 0x75 -> (OP_DROP, s')
    | _, 0x76 -> (OP_DUP, s')
    | _, 0x77 -> (OP_NIP, s')
    | _, 0x78 -> (OP_OVER, s')
    | _, 0x79 -> (OP_PICK, s')
    | _, 0x7a -> (OP_ROLL, s')
    | _, 0x7b -> (OP_ROT, s')
    | _, 0x7c -> (OP_SWAP, s')
    | _, 0x7d -> (OP_TUCK, s')
    | _, 0x6d -> (OP_2DROP, s')
    | _, 0x6e -> (OP_2DUP, s')
    | _, 0x6f -> (OP_3DUP, s')
    | _, 0x70 -> (OP_2OVER, s')
    | _, 0x71 -> (OP_2ROT, s')
    | _, 0x72 -> (OP_2SWAP, s')

    (* Splice *)
    | _, 0x7e -> (OP_CAT, s')
    | _, 0x7f -> (OP_SUBSTR, s')
    | _, 0x80 -> (OP_LEFT, s')
    | _, 0x81 -> (OP_RIGHT, s')
    | _, 0x82 -> (OP_SIZE, s')

    (* Bitwise logic *)
    | _, 0x83 -> (OP_INVERT, s')
    | _, 0x84 -> (OP_AND, s')
    | _, 0x85 -> (OP_OR, s')
    | _, 0x86 -> (OP_XOR, s')
    | _, 0x87 -> (OP_EQUAL, s')
    | _, 0x88 -> (OP_EQUALVERIFY, s')

    (* Arithmetic*)
    | _, 0x8b -> (OP_1ADD, s')
    | _, 0x8c -> (OP_1SUB, s')
    | _, 0x8d -> (OP_2MUL, s')
    | _, 0x8e -> (OP_2DIV, s')
    | _, 0x8f -> (OP_NEGATE, s')
    | _, 0x90 -> (OP_ABS, s')
    | _, 0x91 -> (OP_NOT, s')
    | _, 0x92 -> (OP_0NOTEQUAL, s')
    | _, 0x93 -> (OP_ADD, s')
    | _, 0x94 -> (OP_SUB, s')
    | _, 0x95 -> (OP_MUL, s')
    | _, 0x96 -> (OP_DIV, s')
    | _, 0x97 -> (OP_MOD, s')
    | _, 0x98 -> (OP_LSHIFT, s')
    | _, 0x99 -> (OP_RSHIFT, s')
    | _, 0x9a -> (OP_BOOLAND, s')
    | _, 0x9b -> (OP_BOOLOR, s')
    | _, 0x9c -> (OP_NUMEQUAL, s')
    | _, 0x9d -> (OP_NUMEQUALVERIFY, s')
    | _, 0x9e -> (OP_NUMNOTEQUAL, s')
    | _, 0x9f -> (OP_LESSTHAN, s')
    | _, 0xa0 -> (OP_GREATERTHAN, s')
    | _, 0xa1 -> (OP_LESSTHANOREQUAL, s')
    | _, 0xa2 -> (OP_GREATERTHANOREQUAL, s')
    | _, 0xa3 -> (OP_MIN, s')
    | _, 0xa4 -> (OP_MAX, s')
    | _, 0xa5 -> (OP_WITHIN, s')

    (* Crypto *)
    | _, 0xa6 -> (OP_RIPEMD160, s')
    | _, 0xa7 -> (OP_SHA1, s')
    | _, 0xa8 -> (OP_SHA256, s')
    | _, 0xa9 -> (OP_HASH160, s')
    | _, 0xaa -> (OP_HASH256, s')
    | _, 0xab -> (OP_CODESEPARATOR, s')
    | _, 0xac -> (OP_CHECKSIG, s')
    | _, 0xad -> (OP_CHECKSIGVERIFY, s')
    | _, 0xae -> (OP_CHECKMULTISIG, s')
    | _, 0xaf -> (OP_CHECKMULTISIGVERIFY, s')

    (* Lock time *)
    | _, 0xb1 -> (OP_CHECKLOCKTIMEVERIFY, s')
    | _, 0xb2 -> (OP_CHECKSEQUENCEVERIFY, s')

    (* Pseudo words *)
    | _, 0xfd -> (OP_PUBKEYHASH, s')
    | _, 0xfe -> (OP_PUBKEY, s')
    | _, 0xff -> (OP_INVALIDOPCODE , s')

    (* Reserved words*)
    | _, 0x50 -> (OP_RESERVED, s')
    | _, 0x62 -> (OP_VER, s')
    | _, 0x65 -> (OP_VERIF, s')
    | _, 0x66 -> (OP_VERNOTIF, s')
    | _, 0x89 -> (OP_RESERVED1, s')

    | _, x when x = 0x61 || (x >= 0xb0 && x <= 0xb9) -> (OP_NOP (x), s')
    | _, x -> (OP_NOP (x), s');;

let parse s = let rec parse' s acc = match Bytes.length s with
                    | 0 -> acc
                    | _ -> 
                        let op, s' = opcode_of_hex s in 
                            parse' s' @@ acc @ [op] in 
                                    (parse' s [], String.length s);;

let of_opcodes ops = (ops, List.length ops);;
