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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension DiscordEndpointConsumer where Self: DiscordUserActor {
    /// Default implementation
    func acceptInvite(_ invite: String,
                             callback: ((DiscordInvite?, HTTPURLResponse?) -> ())? = nil) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(DiscordInvite(inviteObject: invite), response)
        }

        rateLimiter.executeRequest(endpoint: .invites(code: invite),
                                   token: token,
                                   requestInfo: .post(content: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }

    /// Default implementation
    func deleteInvite(_ invite: String,
                             reason: String? = nil,
                             callback: ((DiscordInvite?, HTTPURLResponse?) -> ())? = nil) {
        var extraHeaders = [DiscordHeader: String]()

        if let modifyReason = reason {
            extraHeaders[.auditReason] = modifyReason
        }

        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback?(nil, response)

                return
            }

            callback?(DiscordInvite(inviteObject: invite), response)
        }

        rateLimiter.executeRequest(endpoint: .invites(code: invite),
                                   token: token,
                                   requestInfo: .delete(content: nil, extraHeaders: extraHeaders),
                                   callback: requestCallback)
    }

    /// Default implementation
    func getInvite(_ invite: String,
                          callback: @escaping (DiscordInvite?, HTTPURLResponse?) -> ()) {
        let requestCallback: DiscordRequestCallback = { data, response, error in
            guard case let .object(invite)? = JSON.jsonFromResponse(data: data, response: response) else {
                callback(nil, response)

                return
            }

            callback(DiscordInvite(inviteObject: invite), response)
        }

        rateLimiter.executeRequest(endpoint: .invites(code: invite),
                                   token: token,
                                   requestInfo: .get(params: nil, extraHeaders: nil),
                                   callback: requestCallback)
    }
}
