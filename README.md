# ModernNetworking

This package is built to handle networking requests in Swift. It utilizes `async await` and Swift concurrency to handle networking in a modern, reusable way. More specifically, this package allows you to make network requests while specifying a desired `Codable` return type. 

In the current iteration of this package, only a response code of 200 is considered a successful request result. In future iterations, this will be expanded to allow more user customization of what should happen for different response code results.
