## Tests and asserts

To test your installation or use [asserts](https://en.wikipedia.org/wiki/Assertion_(software_development)) as [regression testing](https://en.wikipedia.org/wiki/Regression_testing) after each modification, it is easy.  Run at terminal, in the cloned  project's folder:
```bash
psql  database  < assert01.sql | diff assert01.txt -
```

* [`assert01.sql`](assert01.sql) must result in [`assert01.txt`](assert01.txt). There are a basic test for all functions of the library.

* [`assert02.sql`](assert02.sql) must result in [`assert02.txt`](assert02.txt). It is a "test and example kit" for more complex operations and check result relationships.  Use only tokens to check/confirm also by *token visualization* (explained below).

## Token visulaization

Use for example the site https://s2.sidewalklabs.com/regioncoverer  
or this URL changing the final token code:
https://s2.sidewalklabs.com/regioncoverer/?center=-23.561540%2C-46.656141&zoom=20&cells=94ce59c94ac
