(**
 * Delta Tree
 *
 * @author Nathaniel Gray
 * @version 0.1
 *
 * This is a proof-of-concept of a data structure that can be used, for example,
 * to keep track of marks (or newlines) in a text file while supporting quick
 * insertion and deletion of text.  The main "innovation" comes from storing
 * the elements as offsets rather than absolute values.  I think that this 
 * idea can be applied to almost any type of tree, but I'm using 2-3 trees 
 * because I find them easy to think about.
 * 
 * The idea is that as you dig down into the tree you keep a sum of the
 * deltas that you pass on the right.  So this is one possible tree for
 * the values [50, 75, 100, 130, 150, 200, 295, 297]:
 * {v
                      [ 100 100 ]
                    ___/   |   \___
                   /       |       \
                  [50 25]  [30 20]  [95 2]
   v}            
 * To retrieve the values, perform an inorder walk of the tree, adding the
 * values in each node.  This representation is useful because if you want to
 * insert 35 characters at position 110 you only need to update two entries
 * (marked with * ):
 * {v
                      [ 100 *135 ]
                    ___/   |    \___
                   /       |        \
                  [50 25]  [*65 20]  [95 2]
   v}
 * Text insertion costs h (the height of the tree) additions in the worst
 * case.  Adding or deleting marks has the usual log n cost for element
 * insertion/deletion.
 *
 *)
 
open Printf

let debug = true

module type DeltaTree =
sig
   type 'a t
   
   val empty : 'a t
   val add : 'a t -> int -> 'a -> 'a t
   val find : 'a t -> int -> int * 'a
   val print_tree : ('a -> string) -> 'a t -> unit
   (* val remove : 'a t -> int -> 'a t *)
end

module DeltaTree : DeltaTree =
struct
   type 'elt dtree = 
      Node of 'elt dtree * (int * 'elt) * 'elt dtree * (int * 'elt) option 
                         * 'elt dtree
    | Leaf

   type 'a t = 'a dtree

   let empty = Leaf

   type direction = Left | Center | Right

   let rec print_tree printer indent prefix tree = 
      let print_tree = print_tree printer in
      match tree with
         Leaf -> () (* printf "%s%sLeaf\n" indent prefix *)
       | Node (tl, (pl, el), tc, er_opt, tr) ->
            begin match er_opt with
               Some (pr, er) ->
                  print_tree (indent ^ "      ") "/-" tr;
                  printf "%s%s[%i, %s]\n" indent prefix pr (printer er);
                  print_tree (indent ^ "      ") ">-" tc
             | None ->
                  print_tree (indent ^ "      ") "/-" tc
            end;
            printf "%s%s[%i, %s]\n" indent prefix pl (printer el);
            print_tree (indent ^ "      ") "\\-" tl

   let print_tree printer tree = 
      print_tree printer "" "" tree

   type 'elt pick_subtree_result =
      MatchElt of direction * (int * 'elt)
    | Subtree of direction * (int * 'elt) option * int * 'elt dtree

   (* A utility function *)
   let dtree_pick_subtree d (t1, e1, t2, e2opt, t3) pos =
      (* if debug then
         printf "pick_subtree: %i, %i\n" d pos; *)
      let pos1 = d + fst e1 in
      if pos = pos1 then
         MatchElt (Left, e1)
      else if pos < pos1 then
         Subtree (Left, None, d, t1)
      else
         let d = pos1 in
         match e2opt with
            None ->
               Subtree (Center, Some e1, d, t2)
          | Some e2 ->
               (* if debug then
                  printf "pick_subtree2: %i, %i\n" d pos; *)
               let pos2 = d + fst e2 in
               if pos = pos2 then
                  MatchElt (Right, e2)
               else if pos < pos2 then
                  Subtree (Center, Some e1, d, t2)
               else
                  Subtree (Right, Some e2, pos2, t3)


   let rec dtree_find_pos d best_elt dtree pos : (int * 'elt) option = 
      match dtree with
         Node (t1, e1, t2, e2opt, t3) ->
            begin
               match dtree_pick_subtree d (t1, e1, t2, e2opt, t3) pos with
                  MatchElt (_, e) ->
                     Some e
                | Subtree (_, lparent, d, t) ->
                     begin
                        let best_elt = match lparent with
                           None -> best_elt
                         | e -> e
                        in
                           dtree_find_pos d best_elt t pos
                     end
            end
       | Leaf ->
            best_elt

   (* 
    * Find the element before or at position pos.
    * If the position is before any element, returns None.  Otherwise
    * returns Some (elt_pos, elt).
    *)
   let find dtree pos : (int * 'elt) option =
      dtree_find_pos 0 None dtree pos
   
   let find dtree pos =
      match find dtree pos with
         Some x -> x
       | None -> raise Not_found

   type 'elt insert_result =
      Promote of 'elt dtree * (int * 'elt) * 'elt dtree
    | Done of 'elt dtree

   (* Have to be careful to keep the deltas in shape while unwinding *)
   let unwind_insert d (t1, e1, t2, e2opt, t3) dir result =
      match result, e2opt, dir with
         (* These are the easy Done cases *)
         Done node, _, Left ->
            Done (Node (node, e1, t2, e2opt, t3))
       | Done node, _, Center ->
            Done (Node (t1, e1, node, e2opt, t3))
       | Done node, _, Right ->
            Done (Node (t1, e1, t2, e2opt, node))

         (* These are the easy merge cases *)
       | Promote (tl, e, tr), None, Left ->
            let p = fst e in
            let p1 = fst e1 in
            let e1 = (p1 - p, snd e1) in
               Done (Node (tl, e, tr, Some e1, t2))
       | Promote (tl, e, tr), None, Center ->
            Done (Node (t1, e1, tl, Some e, tr))

         (* These are the merge cases that require promoting an element *)
       | Promote (tl, e, tr), Some e2, Left ->
            let left_tree = Node (tl, e, tr, None, Leaf) in
            let right_tree = Node (t2, e2, t3, None, Leaf) in
               Promote (left_tree, e1, right_tree)
       | Promote (tl, e, tr), Some e2, Center ->
            let p = fst e in
            let p1 = fst e1 in
            let p2 = fst e2 in
            let e = (p1 + p, snd e) in
            let e2 = (p2 - p, snd e2) in
            let left_tree = Node (t1, e1, tl, None, Leaf) in
            let right_tree = Node (tr, e2, t3, None, Leaf) in
               Promote (left_tree, e, right_tree)
       | Promote (tl, e, tr), Some e2, Right ->
            let p1 = fst e1 in
            let p2 = fst e2 in
            let e2 = (p2 + p1, snd e2) in
            let left_tree = Node (t1, e1, t2, None, Leaf) in
            let right_tree = Node (tl, e, tr, None, Leaf) in
               Promote (left_tree, e2, right_tree)
       | _ ->
            failwith "Internal error: unwind_insert"


   let rec dtree_insert_elt d dtree pos elt =
      match dtree with
         Node (t1, e1, t2, e2opt, t3) ->
            begin
               match dtree_pick_subtree d (t1, e1, t2, e2opt, t3) pos with
                  MatchElt (dir, e) ->
                     (* There's already an element at this position 
                        For now just replace it.  Later maybe I should think
                        about this more *)
                     (* if debug then
                        printf "match: %i (%s -> %s)\n" pos (snd e) elt; *)
                     if dir = Left then
                        Done (Node (t1, (pos-d, elt), t2, e2opt, t3))
                     else
                        Done (Node (t1, e1, t2, Some (pos-(fst e1), elt), t3))
                | Subtree (dir, lparent, d', tree) ->
                     let insert_result = dtree_insert_elt d' tree pos elt in
                        unwind_insert d (t1, e1, t2, e2opt, t3) dir 
                              insert_result
            end
       | Leaf ->
            (* if debug then
               printf "promote: %i, %s\n" (pos-d) elt; *)
            Promote (Leaf, (pos-d, elt), Leaf)

   let add dtree pos elt =
      match dtree_insert_elt 0 dtree pos elt with
         Done node ->
            node
       | Promote (tl, e, tr) ->
            Node (tl, e, tr, None, Leaf)
   
   (* let remove dtree pos = *)
      
      
end



let _ =
   let values = [5; 15; 10; 20; 30; 25; 35; 40; 1; 95; 3928; 298; 22; 17; 5] in
   (* let values = List.rev values in *)
   let values = List.map (fun x -> x, string_of_int x ^ "s" ) values in
   let print_tree = DeltaTree.print_tree (fun x-> "\"" ^ x ^ "\"") in
   let dt = DeltaTree.empty in
   let dt = List.fold_left 
         (fun dt (loc, str) -> 
            print_tree dt; print_newline ();
            DeltaTree.add dt loc str)
         dt values
   in
   print_tree dt
   
