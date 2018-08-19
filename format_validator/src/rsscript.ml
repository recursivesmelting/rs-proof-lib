open Stdint

let rec firstk k xs = match xs with
| [] -> xs
| x::xs -> if k=1 then [x] else x::firstk (k-1) xs;;

let rec last = function
    | [] -> failwith "empty"
    | [x] -> x
    | _ :: y -> last y;;


module In_format = struct
    type t = | Tid of {i_token_id : Hash.t;}
             | Tidquantity of {iq_token_id : Hash.t; token_quantity : uint8;}
             | Other;;

    let get_id (input : t) = match input with
        | Tid {i_token_id = x;} -> Some x
        | Tidquantity {iq_token_id = x; token_quantity = _;} -> Some x
        | _ -> None;;

    let get_quantity (input : t) = match input with
        | Tidquantity {iq_token_id = _; token_quantity = x;} -> Some x
        | _ -> None;;
    
    let parse (oplist : Script.opcode list) = let segment = last oplist in
        match segment with 
        | Script.OP_DATA (32, x) -> 
            Tid {
                i_token_id = Bytes.to_string x;
            }
        | Script.OP_DATA (40, x) -> 
            let id = String.sub (Bytes.to_string x) 0 32 in
                let quantity = Uint8.of_bytes_little_endian (Bytes.sub x 32 8) 0 in
            Tidquantity {
                iq_token_id = id;
                token_quantity = quantity;
            }
        | _ -> Other ;;
end

module Out_format = struct
    type t = | Tid of {i_token_id : Hash.t;}
        | Tidquantity of {iq_token_id : Hash.t; token_quantity : uint8;}
        | Topreturn of bytes
        | Other;;

    let get_id (output : t) = match output with
        | Tid {i_token_id = x;} -> Some x
        | Tidquantity {iq_token_id = x; token_quantity = _;} -> Some x
        | _ -> None

    let get_quantity (output : t) = match output with
        | Tidquantity {iq_token_id = _; token_quantity = x;} -> Some x
        | _ -> None;;


    let parse (oplist : Script.opcode list) : t = let segment = firstk 2 oplist in
        match segment with 
        | [Script.OP_DATA (32, x); OP_EQUALVERIFY;] -> 
            Tid {
                i_token_id = Bytes.to_string x;
            }
        | [Script.OP_DATA (40, x); OP_EQUALVERIFY;] -> 
            let id = Bytes.to_string (Bytes.sub x 0 32) in
                let quantity = Uint8.of_bytes_little_endian (String.sub x 32 8) 0 in
            Tidquantity {
                iq_token_id = id;
                token_quantity = quantity;
            }
        | [Script.OP_RETURN x] -> Topreturn x
        | _ -> Other ;;
end

let is_equal_id(x : In_format.t) (y : Out_format.t) = 
    if In_format.get_id x = None || Out_format.get_id y = None then
        false
    else if In_format.get_id x = Out_format.get_id y then
        true
    else
        false;;

let is_equal_id_in(x : In_format.t) (y : In_format.t) = 
    if In_format.get_id x = None || In_format.get_id y = None then
        false
    else if In_format.get_id x = In_format.get_id y then
        true
    else
        false;;

let is_equal_id_out(x : Out_format.t) (y : Out_format.t) = 
    if Out_format.get_id x = None || Out_format.get_id y = None then
        false
    else if Out_format.get_id x = Out_format.get_id y then
        true
    else
        false;;
    
let is_equal_quantity (x : In_format.t) (y : Out_format.t) = 
    if In_format.get_quantity x = None || Out_format.get_quantity y = None then
        false
    else if In_format.get_quantity x = Out_format.get_quantity y then
        true
    else
        false;;

let is_equal (x : In_format.t) (y : Out_format.t) = (is_equal_id x y) && (is_equal_quantity x y);;