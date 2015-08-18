title: Getting to Know Elasticsearch
theme: sjaakvandenberg/cleaver-light
author:
  name: Daniel Paz-Soldan
  twitter: danpazsoldan
output: index.html
controls: true

--

# Getting to Know Elasticsearch
## August 18, 2015

--

### Outline

* Motivation: why do we care about Elasticsearch?
* Overview of concepts.
* Walkthrough building your first index.
* Understand how Elasticsearch works.
* How we use Elasticsearch at Curiosity Media.

Note: This is a huge topic so we will only be able to scratch the surface in this talk. Much of the info comes from *Elasticsearch: The Definitive Guide*. Give it a read!

--

# What is Elasticsearch?

--

### What is Elasticsearch?

* A distributed search engine combining full text search, structured search and analytics.

* A Java application server exposing a RESTful JSON API over HTTP.

* Blazingly fast.

--

### Used by:

 - **Wikipedia** to provide full-text search with highlighted search snippets, and search-as-you-type and did-you-mean suggestions.
 - **The Guardian** to combine visitor logs with social network data to provide real-time feedback to its editors about the public’s response to new articles.
 - **Stack Overflow** to combine full-text search with geolocation queries and uses more-like-this to find related questions and answers.
 - **GitHub** to query 130 billion lines of code.
 - **SpanishDict** to provide search-as-you-type suggestions on over 3.5 million Spanish and English queries, and to display related example sentences for those queries.
 - **PubNation** to aggregate and analyze over 4000 new ad complaints every week.

--

### Concepts

In Elasticsearch, a *document* belongs to a *type*, and those types live inside an *index*.

MySQL => Databases => Tables => Columns/Rows

Elasticsearch => Indices => Types => Documents with Properties

--

### Concepts

* Documents are JSON objects.
* Every field in a document is **indexed** and can be queried.
* **Mappings** define how the data in each field is interpreted.
* **Analyzers** process the text, and the results are used to build an inverted index to make it searchable.
* Elasticsearch implements a complete **Query DSL** for writing search queries against an index.
* **Aggregations** allow us to group and calculate statistics on the data in an index.

--

### Indexing a new document

    curl -XPUT 'http://localhost:9200/gb/tweet/13?pretty=1' -d '
    {
       "date" : "2014-09-23",
       "name" : "Mary Jones",
       "tweet" : "So yes, I am an Elasticsearch fanboy",
       "user_id" : 2
    }
    '

--

### Documents are stored as JSON

`curl -XGET 'http://localhost:9200/_search'`

    {
       "hits" : {
          "total" : 1,
          "hits" : [
            {
               "_index":   "gb",
               "_type":    "tweet",
               "_id":      "1",
               "_score":   1,
               "_source": {
                    "date" : "2014-09-23",
                    "name" : "Mary Jones",
                    "tweet" : "So yes, I am an Elasticsearch fanboy",
                    "user_id" : 2
               }
            }
          ]
        }
        "took" :           4,
        "_shards" : {
          "failed" :      0,
          "successful" :  10,
          "total" :       10
        },
        "timed_out" :      false
    }

--

### The Inverted Index

![inverted index](./img/inverted-index.svg)

--

### The Inverted Index

![inverted index search](./img/inverted-index-search.svg)

--

### Mapping and Analysis

A **Mapping** tells Elasticsearch what data type each field is expected to be, and what Analyzers to use. Analogous to a schema.

An **Analyzer** determines how the text of a particular field will be processed before being indexed. It consists of three steps:

Character filters => Tokenizers => Token filters

Note: The same analysis steps are applied to the query *when you query a full-text field*.

--

### The query DSL

    {
        "query": {
            "bool": {
                "must": { "match":      { "email": "business opportunity" }},
                "should": [
                     { "match":         { "starred": true }},
                     { "bool": {
                           "must":      { "folder": "inbox" }},
                           "must_not":  { "spam": true }}
                     }}
                ],
                "minimum_should_match": 1
            }
        }
    }

--

### Filters and queries

A filter asks a yes/no question of every document and is used for fields that contain exact values:

* Is the `created` date in the range `2013` - `2014`?
* Does the `status` field contain the term `published`?
* Is the `lat_lon` field within `10km` of a specified point?

--

### Filters and queries

A query is similar to a filter, but also asks the question: How well does this document match? A typical use for a query is to find documents:

* Best matching the words `full text search`.
* Containing the word `run`, but maybe also matching `runs`, `running`, `jog`, or `sprint`.
* Containing the words `quick`, `brown`, and `fox` — the closer together they are, the more relevant the document.
* Tagged with `lucene`, `search`, or `java` — the more tags, the more relevant the document.

--

### Performance differences

* The output of a filter search is automatically cached and reused for subsequent requests.
* Queries include relevance scores and thus are **not cachable**.

As a general rule, use query clauses for full-text search or for any condition that should affect the relevance score, and use filter clauses for everything else.

--

### Aggregations

**Aggregations** allow us to group and calculate statistics on the data in an index.

* **Buckets** - Collections of documents that meet a certain criterion (date range, similar terms, etc.).
* **Metrics** - Statistics calculated on the documents in a bucket (max, min, mean, etc.).

--

# Your first Elasticsearch cluster

--

### Your first Elasticsearch cluster

https://github.com/danpaz/elasticsearch-talk/

* Indexing documents.
* Get a single document.
* Search query.
* Filtered query.
* Full-text search.
* Aggregation.
* Delete an index.

--

### From the bottom up

Images from Alex Brasetvik's talk: Elasticsearch From The Bottom Up

https://www.elastic.co/videos/elasticsearch-from-the-bottom-up

--

### A cluster contains one or more nodes

![cluster](./img/slide-cluster.png)

--

### A cluster contains one or more nodes

![nodes](./img/slide-nodes.png)

--

### An index spans one or more shards

![index](./img/slide-index.png)

--

### An index spans one or more shards

![shard](./img/slide-shard.png)

--

### An Elasticsearch shard is essentially a Lucene index

* Apache Lucene is a text search engine library.

![lucene-index](./img/slide-lucene-index.png)

--

### A Lucene index contains multiple index segments

A segment is like a mini index. Each segment contains an inverted index.

![lucene-segment](./img/slide-lucene-segment.png)

---

### The Inverted Index

Searches are executed on all segments, and results are merged before sending back to the client.

![inverted index](./img/inverted-index.svg)

--

### Elasticsearch on SpanishDict

* Megasuggest cluster contains Spanish and English `source` words, indexed using analyzers to great effect!
* Megaexamples cluster contains mgiza example sentences.

--

### Elasticsearch on PubNation

* Treat ad complaints like time-series log data.
* Ad complaints are indexed in Elasticsearch after being inserted to MySQL.
* Filters to narrow down a complete list.
* Aggregations include `date_histogram` and `terms` for the dashboard.
* Autosuggest using `regex` aggregations.

--

### Conclusion

* Motivation: why do we care about Elasticsearch?
* Overview of concepts.
* Walkthrough building your first index.
* Understand how Elasticsearch works.
* How we use Elasticsearch at Curiosity Media.

--

### Resources

* Video: https://www.elastic.co/videos/elasticsearch-from-the-bottom-up?q=from%20the%20bottom
* Elasticsearch: The definitive guide https://www.elastic.co/guide/en/elasticsearch/guide/current/index.html
* Qbox Blog http://blog.qbox.io
