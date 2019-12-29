# S2geometry PoC

Proof of Concept (PoC) for a PostgreSQL implementation of the [S2 Geometry Library](http://S2geometry.io), based on [AfieldTrails/s2-postgis](https://github.com/AfieldTrails/s2-postgis) and [sidewalklabs/s2sphere](https://github.com/sidewalklabs/s2sphere). This library not need PostGIS to run, but in general PostGIS will be used as "context" for geographical applications and library's test.
<!-- S2 cell encoding using the python s2sphere library-->
## Installation

This extension makes it easy to convert GIS data to S2 data types &mdash; S2 cell identifiers (S2cellID's) and S2cellID tokens in particular.

To use, you must [install plpython3u](https://www.enterprisedb.com/edb-docs/d/edb-postgres-advanced-server/installation-getting-started/installation-guide/9.6/EDB_Postgres_Advanced_Server_Installation_Guide.1.60.html) (the PostgreSQL PL/Phyton3 language) and S2Sphere (the python3 exstension) on your Postgresql server.

```
sudo apt-get install postgresql-plpython3-9.6
sudo pip3 install s2sphere
```

To install the extension, clone the respository on your server, then:

```
sudo make install && make installcheck
```

Finally, to actually use the extension:

```
CREATE LANGUAGE plpython3u;
CREATE EXTENSION s2;

SELECT s2_cellid_from_latlng(10.1234, -72.1234);
```

## Types

S2 cell ids are 8-bytes, so fit nicely in PostgreSQL's `bigint`. Tokens are a hex-encoding with the trailing 0's removed, so fit nicely as text.

Either representation will work well for sorted indices. I generally prefer the `bigint` ids but try to provide functions for both when appropriate.

If you're looking at the implementation, there is a dance around converting the unsigned representation used by Python3 and S2sphere and the signed PostgreSQL implementation.

## s2-postgis differences
Listing changes as doing commits:

1. README, file names and formating SQL code.

2. At functions remove all "STRICT" clauses because [it is a PostgreSQL bug](https://github.com/PostgREST/postgrest/issues/1294). To be readable at [PostgREST](https://postgrest.org), the comments are also transformed into SQL comments. Migrating also from public schema to s2gem schema, to simplify isolation (drop cascade only the lib) and review (not polluting public namespace).

3. Add new functions: *s2_cellid_exact_area, s2_token_exact_area, s2_token_get_vertex, s2_token_edge_neighbors_array,s2_token_children_array*...

## Contributions

Functions are added completely opportunistically, so feel free to request something or contribute! If we've missed some best practices or you want to convert it to use the C library instead of python, let we know! Check also evolution of the [AfieldTrails/s2-postgis](https://github.com/AfieldTrails/s2-postgis) project.

----

## Why it is a PoC?

This project will be never a "final project", it is a *proof of concept* because:

1. A serious S2geometry implementation for PostgreSQL **not need a "Python intermediate"** module, both PostgreSQL and S2geometry are C++ sources... But C++ programmers are rare, we can't invest at this moment. If PoC applications evolve we can invest.

2. We are evaluating best human-readable S2CellID representation, using alternatives for hexadecimal token, that **preserves hierarchy** and offer intermediate (half) levels:

    *   base4 instead base16 representation (and transforming 3 bits *face* ID into 4 bits to preserve hierarchy).
    *   testing the use of [**base4h** representation](http://osm.codes/_foundations/art1.pdf), to add "half levels" with its geometry expressed by a [*half level* **degenerated grid**](http://osm.codes/_foundations/art3.pdf).

3. We are evaluating performance and usability of alternatives for PostgreSQL's *internal representation* of S2CellID: [bigint = int8](https://www.postgresql.org/docs/current/datatype-numeric.html#DATATYPE-INT) (most probable), [bitstring](https://www.postgresql.org/docs/current/datatype-bit.html), [bytea](https://www.postgresql.org/docs/current/datatype-binary.html) or [UUID](https://www.postgresql.org/docs/12/datatype-uuid.html).

4. There are a plan to include in the same library all other utility functions that **enable base4h,  base16h and base32 hierarchical representations**,   and functions that enable express (split/merge) cells of the degenerated grid as union of ordinary cells.

5. There are a plan extend library  by wrap functions and some new functions to enable "array algebra", "token albebra"  and another utilities. There are also plans to use the library in a [PostgREST interface](https://postgrest.org), with public serves at *OSM.codes*.
