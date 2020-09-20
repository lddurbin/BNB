# Topics
sparql_1 <-
  'SELECT ?id ?Dewey ?title ?topic
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.
FILTER (contains(?topic,"History") || contains(?topic,"Biograph") || contains(?topic,"Memoir"))

?id dct:title ?title.

?id dct:subject ?d.
?d rdfs:label ?topic.
}'

# Basic fields
sparql_2 <-
  'SELECT ?id ?Dewey ?title
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.
}'

# Contributors
sparql_3 <-
  'SELECT ?id ?Dewey ?contributor ?title
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.

?id dct:contributor ?d.
?d rdfs:label ?contributor.
}'

# Creators
sparql_4 <-
  'SELECT ?id ?Dewey ?creator ?title
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.

?id dct:creator ?c.
?c rdfs:label ?creator.
}'

# Publishers
sparql_5 <-
  'SELECT ?id ?Dewey ?title ?publisher
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.

?id dct:publisher ?d.
?d rdfs:label ?publisher.
}'

# Issue dates
sparql_6 <-
  'SELECT ?id ?Dewey ?title ?issued
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.

?id dct:issued ?issued.
}'

# Descriptions
sparql_7 <-
  'SELECT ?id ?Dewey ?title ?forthcoming
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.

?id dct:description ?forthcoming.

FILTER (?forthcoming = "Forthcoming publication")
}'

# ISBN
sparql_8 <-
  'SELECT ?id ?Dewey ?title ?isbn
WHERE {
?id dct:subject ?b.
?b skos:notation ?Dewey.

?id dct:title ?title.

?id bibo:isbn13 ?isbn.
}'

# Put the SPARQL queries into a vector
sparql_queries <- c(sparql_1, sparql_2, sparql_3, sparql_4, sparql_5, sparql_6, sparql_7, sparql_8)