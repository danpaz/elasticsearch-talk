curl -XGET 'http://localhost:9200/megacorp/employee/_search?pretty=1' -d '
{
  "query": {
    "match": {
      "last_name": "smith"
    }
  },
  "aggs": {
    "all_interests": {
      "terms": {
        "field": "interests"
      }
    }
  }
}
'
