// The MIT License (MIT)
// Copyright (c) 2016 Erik Little

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import Foundation

public extension DiscordEndpoint {
    // MARK: Invites

    /**
        Accepts an invite.

        - parameter invite: The invite code to accept
        - parameter with: The token to authenticate to Discord with
    */
    public static func acceptInvite(_ invite: String, with token: DiscordToken) {
        var request = createRequest(with: token, for: .invites, replacing: [
            "invite.code": invite,
        ])

        request.httpMethod = "POST"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .invites, parameters: ["invite.code": invite])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in })
    }

    /**
        Gets an invite.

        - parameter invite: The invite code to accept
        - parameter with: The token to authenticate to Discord with
        - parameter callback: The callback function, takes an optional `DiscordInvite`
    */
    public static func getInvite(_ invite: String, with token: DiscordToken,
            callback: @escaping (DiscordInvite?) -> Void) {
        var request = createRequest(with: token, for: .invites, replacing: [
            "invite.code": invite,
        ])

        request.httpMethod = "GET"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .invites, parameters: ["invite.code": invite])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard let data = data, response?.statusCode == 200 else {
                callback(nil)

                return
            }

            guard let stringData = String(data: data, encoding: .utf8), let json = decodeJSON(stringData),
                case let .dictionary(invite) = json else {
                    callback(nil)

                    return
            }

            callback(DiscordInvite(inviteObject: invite))
        })
    }
}
