import Foundation

enum runMode {
    case crawl
    case sanitize
    case post
    case news
    case search
    case custom
    case csv
}

let mode:runMode = .csv
let apiEndpoint:URL = URL(string: "https://localhost:8443/api/v1/")!
let localTarget = "/Users/rjq475/Development-vpaa/collapsed/news"
let contentSelector = ".news_article_info"
let siteName = "GLOBAL-WWWROOT"
let contentType = "ROOT EE Page - Content"
let newsContentType = "news/Blog v1.2"
let apiClient = APIClient(baseEndpointURL: apiEndpoint, username: "jgarza", password: "We can make it Saturday forever!") //real secure

switch mode {
    case .crawl:
        let c = Crawler(targetPath:localTarget, targetSelector: contentSelector)
        print("starting crawl")
        c.crawl()
    case .sanitize:
        let s = Sanitizer(targetPath:localTarget, siteName:siteName)
        print("starting sanitize")
        s.crawl()
    case .post:
        var p = Poster(client:apiClient, site: siteName, contentType: contentType, targetPath:localTarget)
        print("starting post")
        _ = p.crawl()
    case .news:
        print("MODE NEWS")
        var n = NewsPoster(client:apiClient, site:siteName, contentType: newsContentType, targetPath:localTarget)
        print("starting news post")
        _ = n.crawl()
    case .search:
        let search = Searcher(client: apiClient, searchTerm: "index", siteName: siteName, searchFields: ["path"], searchTypes: ["page"])
        print("starting search")
        _ = search.searchAndDestroy()
    case .custom:
        var b = Blocker(client:apiClient, site: "NEWFACULTY-VPUR-WWW", targetPath:"/Users/rjq475/Downloads", definitionPath: "Block - New Faculty")
        print("starting search")
        _ = b.crawl()
    case .csv:
        var csvr = CSVer(client: apiClient, site: "PROVOST-VPAA-PROVWEB", targetPath: "/Users/rjq475/Downloads", definitionPath: "SITE/SITE Block - Staff Profile")
        print("starting csv crawl")
        _ = csvr.crawl()
}

while (apiClient.oq.operations.count != 0) {
    _ = DispatchSemaphore(value: 0).wait(timeout: .now() + 5)
    apiClient.oq.waitUntilAllOperationsAreFinished()
}
print("completedOps: \(apiClient.completedOperations)")

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
//let t = semaphore.wait(timeout: .now() + 5)
//print(t)
