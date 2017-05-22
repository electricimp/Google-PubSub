// MIT License
//
// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

class GooglePubSub {
    static VERSION = "0.0.1";
}

class GooglePubSub.Publisher {
    _tokenProvider = null;
    _projectId = null;
    _topicName = null;

    constructor(tokenProvider, projectId, topicName) {
        _tokenProvider = tokenProvider;
        _projectId = projectId;
        _topicName = topicName;
    }

    function _getTopicName() {
        return format("projects/%s/topics/%s", _projectId, _topicName);
    }

    function publishMessage(msg, cb=null) {
        local url = format("https://pubsub.googleapis.com/v1/%s:publish", _getTopicName());

        local message = {
            "messages": [{
                "data": http.base64encode(http.jsonencode(msg))
            }],
        };

        // Get token then make post
        _getHeaders(function(headers) {
            server.log("publish:" + http.jsonencode(message));
            local req = http.post(url, headers, http.jsonencode(message));
            req.sendasync(function(resp) {
                if (resp.statuscode == 200) {
                    // All ok, callback with body, which contains message ID
                    if (cb != null) cb(http.jsondecode(resp.body));
                } else _processResponse(format("Send message: %s", http.jsonencode(msg)), resp);
            }.bindenv(this));
        }.bindenv(this));
    }

    function _getHeaders(cb) {
        _tokenProvider.acquireAccessToken(function(token, err) {
            //server.log("getHeaders: "+token);
            cb({ "Authorization" : format("Bearer %s", token),
                 "Content-Type" : "application/json"})
        }.bindenv(this));
    }

    function _processResponse(op, resp) {
        local statuscode = resp.statuscode;
        server.log(format("%s status: %d", op, statuscode));
        if (statuscode <= 200 || statuscode >= 300) {
            server.log(format("Pubpish response body: %s", resp.body));
        }
    }
}

class GooglePubSub.Subscriber {
    _tokenProvider = null;
    _projectId = null;
    _topicName = null;
    _subscriptionName = null;

    constructor(tokenProvider, projectId, topicName, subscriptionName) {
        _tokenProvider = tokenProvider;
        _projectId = projectId;
        _topicName = topicName;
        _subscriptionName = subscriptionName;
    }

    function _getTopicName() {
        return format("projects/%s/topics/%s", _projectId, _topicName);
    }

    function _getSubscrName() {
        return format("projects/%s/subscriptions/%s", _projectId, _subscriptionName);
    }

    function subscribe(cb) {
        local url = format("https://pubsub.googleapis.com/v1/%s:pull", _getSubscrName());
        local message = {
            "returnImmediately" : false,
            "maxMessages" : 1
        };

        // Get headers then get a message
        _getHeaders(function(headers) {
            local req = http.post(url, headers, http.jsonencode(message));
            req.sendasync(function(resp) {
                local respBody;
                try {
                    respBody = http.jsondecode(resp.body);
                    server.log("subscribe:" + resp.body);

                    if ("receivedMessages" in respBody) {
                        foreach (msg in respBody.receivedMessages) {
                            local rx = http.base64decode(msg.message.data).tostring();
                            server.log(format("Message received: %s", rx));
                            local ackUrl = format("https://pubsub.googleapis.com/v1/%s:acknowledge", _getSubscrName());
                            local ackBody = { "ackIds": [
                                msg.ackId
                            ]};
                            _getHeaders(function(headers) {
                                local ackReq = http.post(ackUrl, headers, http.jsonencode(ackBody));
                                ackReq.sendasync(function(resp) {
                                    if (resp.statuscode != 200) {
                                        _processResponse("acknowledge", resp);
                                    } else {
                                        // ACKed ok, deliver
                                        imp.wakeup(0, function() { cb(rx) });
                                    }
                                }.bindenv(this));
                            });
                        }
                    }

                    // Re-queue the pull
                    imp.wakeup(10, function() { subscribe(cb) }.bindenv(this));
                } catch (exp) {
                    server.log("exception:" +exp);
                    server.log(format("unexpected message: %s", resp.body));
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    function _getHeaders(cb) {
        _tokenProvider.acquireAccessToken(function(token, err) {
            //server.log("getHeaders: "+token);
            cb({ "Authorization" : format("Bearer %s", token),
                 "Content-Type" : "application/json"})
        }.bindenv(this));
    }

    function _processResponse(op, resp) {
        local statuscode = resp.statuscode;
        server.log(format("%s status: %d", op, statuscode));
        if (statuscode < 200 || statuscode >= 300) {
            server.log(format("Subscribe body: %s", resp.body));
        }
    }
}