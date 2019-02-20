import Foundation

let target = "/Users/rjq475/Development-vpaa/collapsed/test-site"

// PHASE TWO (truncation)
// parse each html document
// only keep the content of the page

/*
 
 let c = Crawler(targetPath:target)
c.crawl()

 */

// PHASE THREE
// get back a callapsed model data set
// iterate thru each URL and search and replace relative links

// PHASE FOUR
// iterate over generated snipped
// POST each one to cascade web service for page creation

let myGroup = DispatchGroup()

let dQueue = DispatchQueue(label: "edu.utsa.cascade", qos: .utility)

    let p = Poster(targetPath:target, dispatchQueue:dQueue)
    p.crawl()

while (1 != 2) {
    //do nothing
}

