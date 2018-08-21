open Stdint;;

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
        | Script.OP_DATA (0x20, x) -> let y = Hash.of_bin_norev x in
                Tid {
                    i_token_id = (Bytes.sub y 0 64);
                }
        | Script.OP_DATA (0x28, x) -> let y = Hash.of_bin_norev x in
                    Tidquantity {
                        iq_token_id = (Bytes.sub y 0 64);
                        token_quantity = (Uint8.of_string (Bytes.cat "0x" (String.sub y 64 16)));
                    }
        | _ -> Other ;;
            

            (* let id = (Bytes.sub x 0 32)
            and quantity = (Bytes.sub x 32 8) in
            Tidquantity {
                iq_token_id = Hash.of_bin_norev id;
                token_quantity = let () = (Printf.printf "%i %i \n"
                     (Uint8.to_int (Uint8.of_bytes_little_endian (Hash.of_bin_norev quantity) 1 ))
                    (Uint8.to_int (Uint8.of_bytes_little_endian quantity 0))) in
                    Uint8.of_bytes_little_endian quantity 0;

            }
        | _ -> Other ;; *)
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
        | [Script.OP_DATA (0x20, x); OP_EQUALVERIFY;] -> let y = Hash.of_bin_norev x in
                Tid {
                    i_token_id = (Bytes.sub y 0 64);
                }
        | [Script.OP_DATA (0x28, x); OP_EQUALVERIFY;] -> let y = Hash.of_bin_norev x in
                    Tidquantity {
                        iq_token_id = (Bytes.sub y 0 64);
                        token_quantity = (Uint8.of_string (Bytes.cat "0x" (String.sub y 64 16)));
                    }
        | [Script.OP_RETURN x] -> Topreturn (Hash.of_bin_norev x)
        | _ -> Other ;;
end

let is_equal_id(x : In_format.t) (y : Out_format.t) =
    let () = Printf.printf "In ID: %s \n Out ID: %s \n" 
        (match In_format.get_id x with | Some a -> a | None -> "" ) (match Out_format.get_id y with | Some a -> a | None -> "" )  in
    (if In_format.get_id x = None || Out_format.get_id y = None then
        false
    else if In_format.get_id x = Out_format.get_id y then
        true
    else
        false);;

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