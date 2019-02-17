
let target = "/Users/garza/Development-utsa/collapser/test-site"

// PHASE ONE (collapse)
// crawl targetPath recursively and collapse single item directories
let c = Crawler(targetPath:target)
c.crawl()

// PHASE TWO (truncation)
// parse each html document
// only keep the content of the page

// PHASE THREE
// get back a callapsed model data set
// iterate thru each URL and search and replace relative links


