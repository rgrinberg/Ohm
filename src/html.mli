(* Ohm is © 2012 Victor Nicollet *)

type js

type t = {
  html : Buffer.t ;
  js   : js 
}

type writer = t -> unit

val run : JsCode.t -> writer
val esc : string   -> writer
val str : string   -> writer

val concat : writer list -> writer
val implode : writer list -> writer -> writer

val to_json : writer -> Json_type.t
val to_html_string : writer -> string

module Convenience : sig
    
  val script : string -> writer

  val id : Id.t -> writer

end

type renderer = 
     ?css:string list
  -> ?js:string list
  -> ?head:string
  -> ?favicon:string
  -> ?body_classes:string list
  -> title:string
  -> writer
  -> JsCode.t 
  -> string

type ('ctx) ctxrenderer = 
     ?css:string list
  -> ?js:string list
  -> ?head:string
  -> ?favicon:string
  -> ?body_classes:string list
  -> title:string
  -> writer
  -> ('ctx,(JsCode.t -> string)) Run.t

val print_page : renderer

val print_page_ctx : 'any ctxrenderer
