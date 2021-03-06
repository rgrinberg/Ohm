(* Ohm is © 2012 Victor Nicollet *)

open Util
open BatPervasives

open Action_Common

module Server = Action_Server
module Args   = Action_Args

type ('server,'args) endpoint = 'server -> 'args -> string

let url endpoint s a = endpoint s a 

let endpoint_of_controller (server,prefix,parse) =
  let prefix = path_clean (lowercase prefix) in
  fun s a ->  
    String.concat "/" 
      ( Server.server_root server s :: prefix :: 
	  List.map (Netencoding.Url.encode ~plus:false) (Args.generate parse a))

let rewrite f str sub s a = 
  let url = f s a in
  let _, url = BatString.replace url str sub in
  url
  
let setargs f a s () = 
  f s a 
