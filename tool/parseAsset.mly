%{ 
  
  (* Ohm is © 2012 Victor Nicollet *)
  open SyntaxAsset 

%}

%token < string > STYLE  
%token < string option * string > SCRIPT
%token < SyntaxAsset.pos > OPEN_LIST ELSE OPEN_IF OPEN_OPTION DOT
%token < SyntaxAsset.pos > OPEN OPEN_SUB CLOSE_SUB OPEN_DEF CLOSE_DEF EOL EQUAL CLOSE PIPE
%token < SyntaxAsset.pos > CLOSE_IF CLOSE_LIST CLOSE_OPTION OPEN_SDEF
%token < string * SyntaxAsset.pos > STR MODULE IDENT VARIANT ID
%token < char * SyntaxAsset.pos > ERROR
%token EOF

%start file
%type < SyntaxAsset.cell list > file

%%

file :  
  | cells EOF { $1 }
;

cells : 
  | cell cells { cell $1 :: $2 }
  | { [ ] }
;

cell : 
  | ID { Cell_Id (located $1) } 
  | STYLE { Cell_Style $1 }
  | SCRIPT { let t,s = $1 in Cell_Script (t,s) } 
  | STR { Cell_String (fst $1) }
  | EOL { Cell_String "\n" }
  | OPEN expr CLOSE { Cell_Print $2 }
  | OPEN VARIANT CLOSE { Cell_AdLib (located $2,None) }
  | OPEN VARIANT expr CLOSE { Cell_AdLib (located $2, Some $3) }
  | OPEN_IF expr CLOSE cells CLOSE_IF { Cell_If ($2,$4,[]) }
  | OPEN_IF expr CLOSE cells ELSE cells CLOSE_IF { Cell_If ($2,$4,$6) }
  | OPEN_SUB expr CLOSE cells CLOSE_SUB { Cell_Sub ($2,$4) }
  | OPEN_DEF IDENT CLOSE cells CLOSE_DEF { Cell_Define (true,located $2,$4) }
  | OPEN_SDEF IDENT CLOSE cells CLOSE_DEF { Cell_Define (false,located $2,$4) }
  | OPEN_LIST expr CLOSE cells CLOSE_LIST { Cell_List (None,$2,$4,[]) }
  | OPEN_LIST expr CLOSE cells ELSE cells CLOSE_LIST { Cell_List (None,$2,$4,$6) }
  | OPEN_LIST IDENT EQUAL expr CLOSE cells CLOSE_LIST { Cell_List (Some (located $2),$4,$6,[]) }
  | OPEN_LIST IDENT EQUAL expr CLOSE cells ELSE cells CLOSE_LIST { Cell_List (Some (located $2),$4,$6,$8) }
  | OPEN_OPTION expr CLOSE cells CLOSE_OPTION { Cell_Option (None,$2,$4,[]) }
  | OPEN_OPTION expr CLOSE cells ELSE cells CLOSE_OPTION { Cell_Option (None,$2,$4,$6) }
  | OPEN_OPTION IDENT EQUAL expr CLOSE cells CLOSE_OPTION { Cell_Option (Some (located $2),$4,$6,[]) }
  | OPEN_OPTION IDENT EQUAL expr CLOSE cells ELSE cells CLOSE_OPTION { Cell_Option (Some (located $2),$4,$6,$8) }
;
  
expr : 
  | MODULE DOT func   { (None, [located $1 :: $3]) }  
  | MODULE DOT func PIPE pipes { (None, (located $1 :: $3) :: $5) }  
  | IDENT             { (Some (located $1),[]) } 
  | IDENT PIPE pipes  { (Some (located $1),$3) } 
;

pipes : 
  | func             { [$1] } 
  | func PIPE pipes  { $1 :: $3 } 
;

func : 
  | MODULE DOT func  { located $1 :: $3 } 
  | IDENT            { [located $1] } 
;
