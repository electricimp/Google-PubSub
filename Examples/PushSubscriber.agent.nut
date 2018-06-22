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

// OAuth 2.0 library required for GooglePubSub
#require "OAuth2.agent.lib.nut:1.0.0"

#require "GooglePubSub.agent.lib.nut:1.0.0"

// GooglePubSub.PushSubscriber and GooglePubSub.Subscriptions demo.
// Creates a push subscription (related to imp Agent URL) to the specified topic
// (topic name, subscription name and push subscription secret token are specified as
// constructor arguments), receives messages from it and prints messages data and
// attributes to the log.
// Messages are acknowledged automatically by GooglePubSub.PushSubscriber library.
class PushSubscriber {
    _topicName = null;
    _subscrName = null;
    _secretToken = null;
    _topics = null;
    _subscrs = null;
    _pushSubscriber = null;

    constructor(projectId, oAuthTokenProvider, topicName, subscrName, secretToken = null) {
        _topicName = topicName;
        _subscrName = subscrName;
        _secretToken = secretToken;
        _topics = GooglePubSub.Topics(projectId, oAuthTokenProvider);
        _subscrs = GooglePubSub.Subscriptions(projectId, oAuthTokenProvider);
        _pushSubscriber = GooglePubSub.PushSubscriber(projectId, oAuthTokenProvider, subscrName);
    }

    // Handler function to be executed when incoming push messages are received
    function onMessagesReceived(error, messages) {
        if (error) {
            server.error("Messages received error: " + error.details);
        }
        else {
            server.log("Messages received:");
            foreach (msg in messages) {
                server.log(format("data: %s, attrs: %s, publishTime: %s",
                    msg.data ? http.jsonencode(msg.data) : "null",
                    msg.attributes ? http.jsonencode(msg.attributes) : "null",
                    msg.publishTime));
            }
        }
    }

    // Checks if the specified push subscription exists and optionally creates it if not,
    // then sets messages handler to receive incoming push messages
    function subscribe() {
        _topics.obtain(_topicName, null, function (error) {
            if (error && error.type == PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED && error.httpStatus == 404) {
                server.error(format("Topic %s doesn't exist. Impossible to create a subscription.", _topicName));
            }
            else {
                local subscrOptions = {
                    "autoCreate" : true,
                    "subscrConfig" : GooglePubSub.SubscriptionConfig(
                        _topicName, 10, GooglePubSub.PushConfig(_subscrs.getImpAgentEndpoint(null, _secretToken)))
                };
                _subscrs.obtain(_subscrName, subscrOptions, function (error, subscrConfig) {
                    if (error) {
                        server.error("Subscription obtain request failed: " + error.details);
                    }
                    else {
                        _pushSubscriber.setMessagesHandler(onMessagesReceived, function (error) {
                            if (error) {
                                server.error("setMessagesHandler failed: " + error.details);
                            }
                        });
                    }
                }.bindenv(this));
            }
        }.bindenv(this));
    }
}

// Configuration constants, substitute with real values
const PROJECT_ID = "...";
const GOOGLE_ISS = "...";
const GOOGLE_SECRET_KEY = "...";

// obtaining OAuth2 Access Tokens Provider
local oAuthTokenProvider = OAuth2.JWTProfile.Client(
    OAuth2.DeviceFlow.GOOGLE,
    {
        "iss"         : GOOGLE_ISS,
        "jwtSignKey"  : GOOGLE_SECRET_KEY,
        "scope"       : "https://www.googleapis.com/auth/pubsub"
    });

const TOPIC_NAME = "test_topic";
const SUBSCR_NAME = "test_push_subscription";
const SECRET_TOKEN = "secret_token";

// Start Application
pushSubscriber <- PushSubscriber(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME, SUBSCR_NAME, SECRET_TOKEN);
pushSubscriber.subscribe();
