import Foundation

enum runMode {
    case crawl
    case sanitize
    case post
}

let mode:runMode = .post

let apiEndpoint:URL = URL(string: "https://localhost:8443/api/v1/")!
//let apiClient = APIClient(baseEndpointURL: apiEndpoint, username: "jgarza", password: "ashore-slither-cement") //real secure
let apiClient = APIClient(baseEndpointURL: apiEndpoint, username: "admin", password: "admin") //real securelet target = "/Users/garza/Development-utsa/collapser/test-site"
//let target = "/Users/rjq475/Development-vpaa/collapsed/test-site"
let target = "/Users/garza/Development-utsa/collapser/test-site"
let siteName = "GLOBAL-WWWROOT"
let contentType = "ROOT Global Page - Content Rows"
let semaphore = DispatchSemaphore(value: 0)
let dQueue = DispatchQueue(label: "edu.utsa.cascade", qos: .utility)
let c = Crawler(targetPath:target)
let s = Sanitizer(targetPath:target, siteName:siteName)
var p = Poster(client:apiClient, site: siteName, contentType: contentType, targetPath:target, dispatchQueue:dQueue, semaphore:semaphore)

switch mode {
    case .crawl:
        print("starting crawl")
        c.crawl()
    case .sanitize:
        print("starting sanitize")
        s.crawl()
    case .post:
        print("starting post")
        let processed:Int = p.crawl()
        print("processed count: \(processed)")
}

// PHASE TWO (truncation)
// parse each html document
// only keep the content of the page
//c.crawl()

// PHASE THREE
// iterate thru each snippet and search and replace relative links
//s.crawl()

// PHASE FOUR
// iterate over generated snipped
// POST each one to cascade web service for page creation
//p.crawl()
let t = semaphore.wait(timeout: .now() + 5)
print(t)
