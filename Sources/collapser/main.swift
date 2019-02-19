
let target = "/Users/garza/Development-utsa/collapser/test-site"

// PHASE TWO (truncation)
// parse each html document
// only keep the content of the page

//let c = Crawler(targetPath:target)
//c.crawl()

// PHASE THREE
// get back a callapsed model data set
// iterate thru each URL and search and replace relative links

// PHASE FOUR
// iterate over generated snipped
// POST each one to cascade web service for page creation

let p = Poster(targetPath:target)
p.crawl()


