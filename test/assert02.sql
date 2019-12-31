
-- Complementig tests --

--
-- Composite functions:
--
SELECT s2_cellid_is_leaf( s2_cellid_from_token('89c288') )  ;  -- f
SELECT s2_cellid_is_leaf( s2_cellid_from_latlng(-23.55041,-46.63394) ); --  t

--
-- Loops for levels and neighbors:
--

SELECT 1+i*5 as level,
       s2_cellid_exact_area( s2_cellid_parent( s2_cellid_from_latlng(-23.55041,-46.63394), 1+i*5) ) "pt1_area_byID",
       s2_cellid_exact_area( s2_cellid_parent( s2_cellid_from_latlng(15,15), 1+i*5) ) "pt2_area_byID",
       s2_cellid_exact_area( s2_cellid_parent( s2_cellid_from_latlng(-23.55041,-46.63394), 1+i*5) ) "pt1_metricArea",
       s2_cellid_exact_area( s2_cellid_parent( s2_cellid_from_latlng(15,15), 1+i*5) ) "pt2_metricArea"
FROM generate_series(0,5) t(i);

SELECT 1+i*5 as level,
       s2_token_exact_area( s2_token_parent( s2_token_from_latlng(-23.55041,-46.63394), 1+i*5) ) "pt1_area_byToken",
       s2_token_exact_area( s2_token_parent( s2_token_from_latlng(15,15), 1+i*5) ) "pt2_area_byToken",
       s2_token_exact_area( s2_token_parent( s2_token_from_latlng(-23.55041,-46.63394), 1+i*5), true ) "pt1_metricArea",
       s2_token_exact_area( s2_token_parent( s2_token_from_latlng(15,15), 1+i*5), true ) "pt2_metricArea"
FROM generate_series(0,5) t(i);


SELECT 5+i*4 as level, token, s2_token_exact_area( s2_token_parent(token,1+i*2) )
FROM generate_series(0,3) t(i), s2_token_edge_neighbors('94ce59c') g(token);


/*
 use for teste on array and s2_token_contains
 94ce59c94ac contains "94ce59c94ab,94ce59c94ad,94ce59c94a9,94ce59c94af"

SELECT s2_cellid_from_token('94ce59c94ac') parent,
       s2_cellid_from_token('94ce59c94a9') c0,
       s2_cellid_from_token('94ce59c94ab') c1,
       s2_cellid_from_token('94ce59c94ad') c2,
       s2_cellid_from_token('94ce59c94af') c3;
SELECT s2_token_edge_neighbors('94ce59c94a9') c0_neighbors;
-- container do nivel 11 (com mais de 1km) 94ce59c, nivel 10 94ce59, nivel 9 94ce5c.

SELECT s2_cellid_from_token('94ce59c94ac') c1_level19,
       s2_cellid_from_token('94ce59c9') c2_level14,
       s2_cellid_from_token('94ce59c') c2_level11,
       s2_cellid_from_token('94ce59') c3_level10,
       s2_cellid_from_token('94ce5c') c4_level9; -- s2_token_parent('94ce59c94ac',9)

*/
