-- Requires plpython3u language to be installed
-- CREATE LANGUAGE plpython3u;
-- Also requires the s2sphere extension to be installed on the system for python3.

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION s2" to load this file. \quit
-- that is: CREATE plpython3u and s2 EXTENSIONs before load this file


--
-- Conversion functions
--

-- PostgreSQL doesn't handle Unsigned Bigint, so we have to re-interpret the byte representation
-- of the id.
CREATE or replace FUNCTION s2_cellid_from_latlng(lat double precision, lng double precision) RETURNS bigint
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_lat_lng(s2sphere.LatLng.from_degrees(lat, lng))
  return int.from_bytes(id.id().to_bytes(8, 'big', signed=False), 'big', signed=True)
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_cellid_from_latlng IS 'Convert from  latitude and longitude to cellid (long)';

CREATE or replace FUNCTION s2_cellid_from_token(token text) RETURNS bigint
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  return int.from_bytes(id.id().to_bytes(8, 'big', signed=False), 'big', signed=True)
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_cellid_from_token IS 'Convert from token (text) to cellid (long) representation';

CREATE or replace FUNCTION s2_token_from_latlng(lat double precision, lng double precision) RETURNS text
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_lat_lng(s2sphere.LatLng.from_degrees(lat, lng))
  return id.to_token()
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_token_from_latlng IS 'Get the string token for a cellid from the latitude and longitude';

CREATE or replace FUNCTION s2_token_from_cellid(cellid bigint) RETURNS text
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  return id.to_token()
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_token_from_cellid IS 'Get the string token for a cellid from the raw id';

CREATE or replace FUNCTION s2_latlng_from_cellid(cellid bigint, OUT lat double precision, OUT lng double precision)
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  latlng = id.to_lat_lng()
  return (latlng.lat().degrees, latlng.lng().degrees)
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_latlng_from_cellid IS 'Get the latitude and longitude as degrees from a cellid';

CREATE or replace FUNCTION s2_latlng_from_token(token text, OUT lat double precision, OUT lng double precision)
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  latlng = id.to_lat_lng()
  return (latlng.lat().degrees, latlng.lng().degrees)
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_latlng_from_token IS 'Get the latitude and longitude as degrees from a token';


--
-- CellId based functions
--

-- Return whether this is a valid s2 cellid.
CREATE or replace FUNCTION s2_cellid_is_valid(cellid bigint) RETURNS boolean
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  return id.is_valid()
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_cellid_is_leaf(cellid bigint) RETURNS boolean
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  return id.is_leaf()
$f$ LANGUAGE plpython3u IMMUTABLE;

-- Return the level of the cellid
CREATE or replace FUNCTION s2_cellid_level(cellid bigint) RETURNS int
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  return id.level()
$f$ LANGUAGE plpython3u IMMUTABLE;

-- Return a cell id at a parent level for the passed in cell id
CREATE or replace FUNCTION s2_cellid_parent(cellid bigint, parent_level int) RETURNS bigint
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  newid = id.parent(parent_level)
  return int.from_bytes(newid.id().to_bytes(8, 'big', signed=False), 'big', signed=True)
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_cellid_children(cellid bigint) RETURNS SETOF bigint
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  if not id.is_leaf():
    for child in id.children():
      yield int.from_bytes(child.id().to_bytes(8, 'big', signed=False), 'big', signed=True)
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_cellid_edge_neighbors(cellid bigint) RETURNS SETOF bigint
AS $f$
  import s2sphere
  id = s2sphere.CellId(int.from_bytes(cellid.to_bytes(8, 'big', signed=True), 'big', signed=False))
  for neighbor in id.get_edge_neighbors():
    yield int.from_bytes(neighbor.id().to_bytes(8, 'big', signed=False), 'big', signed=True)
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_cellid_contains(a bigint, b bigint) RETURNS boolean
AS $f$
  import s2sphere
  id_a = s2sphere.CellId(int.from_bytes(a.to_bytes(8, 'big', signed=True), 'big', signed=False))
  id_b = s2sphere.CellId(int.from_bytes(b.to_bytes(8, 'big', signed=True), 'big', signed=False))
  return id_a.contains(id_b)
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_cellid_intersects(a bigint, b bigint) RETURNS boolean
AS $f$
  import s2sphere
  id_a = s2sphere.CellId(int.from_bytes(a.to_bytes(8, 'big', signed=True), 'big', signed=False))
  id_b = s2sphere.CellId(int.from_bytes(b.to_bytes(8, 'big', signed=True), 'big', signed=False))
  return id_a.intersects(id_b)
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_cellid_exact_area(id0 bigint, ret_meters boolean DEFAULT false) RETURNS float8
AS $f$
  import s2sphere
  id = s2sphere.CellId(
       int.from_bytes( id0.to_bytes(8,'big',signed=True), 'big', signed=False )
  )
  kEarthRadiusMeters =  6371010
  steradians = s2sphere.Cell( id ).exact_area()
  return (steradians*kEarthRadiusMeters*kEarthRadiusMeters) if ret_meters else steradians
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_cellid_exact_area IS 'Exact area in steradians of a cell-ID, and approximated (better for small cells) in meters';


--
-- Token based functions
--

-- Return whether this is a valid s2 cellid.
CREATE or replace FUNCTION s2_token_is_valid(token text) RETURNS boolean
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  return id.is_valid()
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_token_is_leaf(token text) RETURNS boolean
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  return id.is_leaf()
$f$ LANGUAGE plpython3u IMMUTABLE;

-- Return the level of the cellid
CREATE or replace FUNCTION s2_token_level(token text) RETURNS int
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  return id.level()
$f$ LANGUAGE plpython3u IMMUTABLE;

-- Return a cell id at a parent level for the passed in cell id
CREATE or replace FUNCTION s2_token_parent(token text, parent_level int) RETURNS text
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  newid = id.parent(parent_level)
  return newid.to_token()
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_token_children(token text) RETURNS SETOF text
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  if not id.is_leaf():
    for child in id.children():
      yield child.to_token()
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_token_edge_neighbors(token text) RETURNS SETOF text
AS $f$
  import s2sphere
  id = s2sphere.CellId.from_token(token)
  for neighbor in id.get_edge_neighbors():
    yield neighbor.to_token()
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_token_contains(a text, b text) RETURNS boolean
AS $f$
  import s2sphere
  id_a = s2sphere.CellId.from_token(a)
  id_b = s2sphere.CellId.from_token(b)
  return id_a.contains(id_b)
$f$ LANGUAGE plpython3u IMMUTABLE;

CREATE or replace FUNCTION s2_token_intersects(a text, b text) RETURNS boolean
AS $f$
  import s2sphere
  id_a = s2sphere.CellId.from_token(a)
  id_b = s2sphere.CellId.from_token(b)
  return id_a.intersects(id_b)
$f$ LANGUAGE plpython3u IMMUTABLE;

-- new, from 2019 changes:

CREATE or replace FUNCTION s2_token_exact_area(token text, ret_meters boolean DEFAULT false) RETURNS float8 AS $f$
  import s2sphere
  kEarthRadiusMeters =  6371010
  steradians = s2sphere.Cell( s2sphere.CellId.from_token(token) ).exact_area()
  return (steradians*kEarthRadiusMeters*kEarthRadiusMeters) if ret_meters else steradians
$f$ LANGUAGE plpython3u IMMUTABLE;
COMMENT ON function s2_cellid_exact_area IS 'Exact area in steradians of a cell-Token, and approximated (better for small cells) in meters';


CREATE or replace FUNCTION s2_token_get_vertex(token text, k int,  OUT r float[])
AS $f$
  import s2sphere
  point = s2sphere.Cell( s2sphere.CellId.from_token(token) ).get_vertex(k)
  return ( point[0],  point[1],  point[2]) # a point on the unit sphere
$f$ LANGUAGE plpython3u IMMUTABLE;
-- but ideal is GeoJSON, see clues at https://github.com/google/s2-geometry-library-java/issues/5

--
-- s2_token wrap functions:

CREATE or replace FUNCTION s2_token_edge_neighbors_array(token text) RETURNS text[]
AS $wrap$
  SELECT array_agg(x) FROM s2_token_edge_neighbors(token) t(x)
$wrap$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION s2_token_children_array(token text) RETURNS text[]
AS $wrap$
  SELECT array_agg(x) FROM s2_token_children(token) t(x)
$wrap$ LANGUAGE SQL IMMUTABLE;
