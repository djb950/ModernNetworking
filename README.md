# ModernNetworking

A Swift package for simplifying making networking requests and decoding 'Codable' objects.

Decoding `Codable` objects have made it a lot simpler to decode JSON and make network requests on iOS platforms. Over the years of working on various iOS applications, a large portion of networking code can become repetitive. This package makes it simpler to configure and make networking requets and decode `Codable` objects.

## Usage

Simply call the `NetworkManager.request` method. 

### Parameters

`endpoint`
A generic endpoint constrained to `RawRepresentable`. A good way to do this is to have an enum representing the different endpoints

`requestMethod`
The HTTP request method. Currently only GET and POST are supported. Query items/request body can be supplied as well

`responseType`
A generic object constrained to `Codable`

`customDecoder`
An instance of `JSONDecoder`. Allows more granular control over decoding behavior. Optional

`statusCodeActions`
A dictionary of `[HTTPStatusCode : HTTPStatusAcrtion<T>]`. Allows for customization of what action should take place for each HTTP status code. Defaults to an empty dictionary with the assumption that a 200 is successful and any other status code is a failed result

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
let response = try await NetworkManager().request(
    endpoint: DummyEndpoint.catFacts,
    requestMethod: .get(queryItems: nil),
    responseType: [CatFact].self,
    customDecoder: nil, statusCodeActions: [:]
)


