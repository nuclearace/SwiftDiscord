// The MIT License (MIT)
// Copyright (c) 2017 Erik Little

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

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    public func acceptInvite(_ invite: String, callback: ((DiscordInvite?) -> ())? = nil) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)
                return
            }
            callback?(DiscordInvite(inviteObject: invite))
        }
        rateLimiter.executeRequest(endpoint: .invites(code: invite),
                                   token: token,
                                   requestInfo: .post(content: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    public func deleteInvite(_ invite: String, callback: ((DiscordInvite?) -> ())? = nil) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil)
                return
            }
            callback?(DiscordInvite(inviteObject: invite))
        }
        rateLimiter.executeRequest(endpoint: .invites(code: invite),
                                   token: token,
                                   requestInfo: .delete,
                                   callback: requestCallback)
    }

    /// Default implementation
    public func getInvite(_ invite: String, callback: @escaping (DiscordInvite?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil)
                return
            }
            callback(DiscordInvite(inviteObject: invite))
        }
        rateLimiter.executeRequest(endpoint: .invites(code: invite),
                                   token: token,
                                   requestInfo: .get(params: nil),
                                   callback: requestCallback)
    }
}
