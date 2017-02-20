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
        - parameter callback: An optional callback containing the accepted invite, if successful
    */
    public static func acceptInvite(_ invite: String, with token: DiscordToken, callback: ((DiscordInvite?) -> Void)?) {
        var request = createRequest(with: token, for: .invites, replacing: [
            "invite.code": invite,
        ])

        request.httpMethod = "POST"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .invites, parameters: ["invite.code": invite])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(invite)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordInvite(inviteObject: invite))
        })
    }

    /**
        Deletes an invite.

        - parameter invite: The invite code to delete
        - parameter with: The token to authenticate to Discord with
        - parameter callback: An optional callback containing the deleted invite, if successful
    */
    public static func deleteInvite(_ invite: String, with token: DiscordToken, callback: ((DiscordInvite?) -> Void)?) {
        var request = createRequest(with: token, for: .invites, replacing: [
            "invite.code": invite,
        ])

        request.httpMethod = "DELETE"

        let rateLimiterKey = DiscordRateLimitKey(endpoint: .invites, parameters: ["invite.code": invite])

        DiscordRateLimiter.executeRequest(request, for: rateLimiterKey, callback: {data, response, error in
            guard case let .object(invite)? = self.jsonFromResponse(data: data, response: response) else {
                callback?(nil)

                return
            }

            callback?(DiscordInvite(inviteObject: invite))
        })
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
            guard case let .object(invite)? = self.jsonFromResponse(data: data, response: response) else {
                callback(nil)

                return
            }

            callback(DiscordInvite(inviteObject: invite))
        })
    }
}
