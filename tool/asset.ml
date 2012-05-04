(* Ohm is © 2012 Victor Nicollet *)

let parse lexbuf =
  let reader = TokenAsset.read () in
  let stream = ParseAsset.file reader lexbuf in
  stream
  
let extract_strings streams = 
  List.fold_right 
    (fun (asset,stream) (current,out) -> 
      let current, stream = SyntaxAsset.extract_strings current stream in 
      (current, (asset,stream) :: out))
    streams (SyntaxAsset.({
      html = "" ;
      css  = Buffer.create 16
    }),[])
  
let extract_assets streams = 
  List.fold_left
    (fun out (revpath,stream) -> 
      let out, asset = SyntaxAsset.extract_assets revpath out stream in
      (revpath, asset) :: out)
    [] streams

let chain_of_revpath revpath = 
  String.concat "_" 
    (List.rev_map String.capitalize revpath)

let  ml_of_revpath revpath = "asset_" ^ chain_of_revpath revpath ^ ".ml"
let mli_of_revpath revpath = ml_of_revpath revpath ^ "i"

let module_of_revpath revpath = "Asset_" ^ chain_of_revpath revpath 

type generation = 
  [ `Stmt of string
  | `Indent of generation list ] 
    
let print_generated l = 
  let b = Buffer.create 16 in
  let rec gen indent = function
    | `Stmt   s -> Buffer.add_string b indent ; Buffer.add_string b s ; Buffer.add_char b '\n'
    | `Indent l -> List.iter (gen (indent ^ "  ")) l 
  in
  List.iter (gen "") l ;
  Buffer.contents b 

let header = "(* This asset file was generated by ohm-tool *)"
let (!!) fmt = Printf.sprintf fmt 

let generate_source string = 
  
  let the_struct = 
    print_generated [
      `Stmt header ; 
      `Stmt (!! "let source = %S" string) 
    ]

  and the_sig = 
    print_generated [
      `Stmt header ;
      `Stmt "val source : string"
    ]
  in

  [ "assetData.ml", the_struct ; "assetData.mli", the_sig ] 

let generate_asset revpath asset = 

  let root : SyntaxAsset.cell_root = SyntaxAsset.extract_roots asset in 

  let the_struct = 
    
    let print_cell = function 
      | `Print uid    -> Some (`Stmt (!! "_%d _html ;" uid))
      | `String (_,0) -> None
      | `String (start,length) -> Some (
	`Stmt (!! "Buffer.add_substring _html.Ohm.Html.html _source %d %d ;"
		  start length))
    in

    let rec print_root = function 
      | `Render [] -> [ `Stmt "Ohm.Run.return ignore" ] 
      | `Render cells -> 
	[ `Stmt "Ohm.Run.return (fun _html ->" 
	; `Indent ((BatList.filter_map print_cell cells))
	; `Stmt ")" ]
      | `Extract (uid,name,tail) -> 
	( `Stmt (!! "let  _%d = _data # %s in" uid (SyntaxAsset.contents name) ) )
	:: print_root tail
      | `Apply (uid,uid',what,tail) -> 
	( `Stmt (!! "let  _%d = _%d |> %s in" uid uid' 
		    (String.concat "." (List.map SyntaxAsset.contents what))))
	:: print_root tail
      | `Ohm (uid,uid',tail) -> 
	(`Stmt (!! "let! _%d = Ohm.Universal.ohm _%d in" uid uid'))
	:: print_root tail
      | `Put (uid,uid',`Raw,tail) -> 
	(`Stmt (!! "let  _%d _html = Buffer.add_string _html.Ohm.Html.html _%d in" 
		   uid uid'))
	:: print_root tail
      | `Put (uid,uid',`Esc,tail) -> 
	(`Stmt (!! "let  _%d = Ohm.Html.esc _%d in" uid uid'))
	:: print_root tail
      | `If (uid,uid',if_true,if_false,tail) -> 
	(`Stmt (!! "let! _%d = Ohm.Universal.ohm begin" uid))
	:: (`Indent [ `Stmt (!! "if _%d then" uid') 
		    ; `Indent (print_root if_true) 
		    ; `Stmt "else" 
		    ; `Indent (print_root if_false) 
		    ])
	:: (`Stmt "end in") 
	:: print_root tail 
      | `Sub (uid,uid',what,tail) -> 
	(`Stmt (!! "let! _%d = Ohm.Universal.ohm begin" uid))
	:: (`Indent ( `Stmt (!! "let _data = _%d in" uid') 
		      :: print_root what ))
	:: (`Stmt "end in") 
	:: print_root tail 
      | `Call (uid,revpath,tail) -> 
	(`Stmt (!! "let! _%d = Ohm.Universal.ohm (%s.render _data) in"
		   uid (module_of_revpath revpath)))
	:: print_root tail 
      | `Option (uid,_,uid',if_some,if_none,tail) -> 
	(`Stmt (!! "let! _%d = Ohm.Universal.ohm begin" uid))
	:: (`Indent [ `Stmt (!! "match _%d with" uid') 
		    ; `Stmt "| None ->" 
		    ; `Indent (print_root if_none) 
		    ; `Stmt "| Some _data ->" 
		    ; `Indent (print_root if_some) ])
	:: (`Stmt "end in") 
	:: print_root tail 
      | `List (uid,_,uid',if_list,if_none,tail) -> 
	(`Stmt (!! "let! _%d = Ohm.Universal.ohm begin" uid))
	:: (`Indent [ `Stmt (!! "match _%d with" uid') 
		    ; `Stmt "| [] ->" 
		    ; `Indent (print_root if_none) 
		    ; `Stmt "| _list -> " 
		    ; `Indent [ `Stmt "let! _render = Ohm.Universal.ohm (Ohm.Run.list_map (fun _data ->" 
			      ; `Indent (print_root if_list) 
			      ; `Stmt ") _list) in" 
			      ; `Stmt "Ohm.Run.return (Ohm.Html.concat _render)" ]])
	:: (`Stmt "end in") 
	:: print_root tail 
    in

    let contents =
      ( `Stmt header ) 
      :: ( `Stmt "open BatPervasives" ) 
      :: ( `Stmt "let _source = AssetData.source" )
      :: ( `Stmt "let bind = Ohm.Universal.bind" )
      :: ( `Stmt "let render _data =" )
      :: [ `Indent (print_root root) ]
    in

    print_generated contents

  in

  [ ml_of_revpath revpath, the_struct ] 
