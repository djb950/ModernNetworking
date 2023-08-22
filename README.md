# ModernNetworking

A Swift package for simplifying making networking requests and decoding 'Codable' objects.

Decoding `Codable` objects have made it a lot simpler to decode JSON and make network requests on iOS platforms. Over the years of working on various iOS applications, a large portion of networking code can gets repeated. This package makes it simpler to configure and make networking requets and decode `Codable` objects.

## Usage

Simply call the `NetworkManager.request` method. This method takes in an endpoint parameter, which is a generic parameter constrained to `RawRepresentable`. A good way to do this is to have an enum representing the different endpoints of whatever backend you want to hit. You can specify the HTTP request method. Currently only GET and POST are supported. For a GET request, you may supply query items, or for a POST request, you can supply a request body. You will also need to supply the responseType that you want to decode. This is also a generic parameter constrained to `Codable`. You also can supply a custom `JSONDecoder`, otherwise it will default to the default `JSONDecoder`. This package allows you to also supply actions for each HTTP status code, allowing for custom behavior for certain response codes. If you do not supply any of these, a 200 code will be considered a successful result, and everything else is considered a failed result.
```
// Enum representing the endpoints to hit
enum DummyEndpoint: String {
    case catFacts = "https://cat-fact.herokuapp.com/facts/"
}

// Codable object representing what to decode on a successful response
struct CatFact: Codable, Equatable {
    static func == (lhs: CatFact, rhs: CatFact) -> Bool {
        return lhs._id == rhs._id
    }
    
    struct CatFactStatus: Codable {
        let verified: Bool
        let sentCount: Int
    }
    
    let status: CatFactStatus
    let _id: String
    let user: String
    let text: String
    let __v: Int
    let source: String
    let updatedAt: String
    let type: String
    let createdAt: String
    let deleted: Bool
    let used: Bool
}

// Network request
let response = try await NetworkManager().request(endpoint: DummyEndpoint.catFacts, requestMethod: .get(queryItems: nil), responseType: [CatFact].self, customDecoder: nil)


