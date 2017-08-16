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

#require "GooglePubSub.agent.lib.nut:1.0.0"
// OAuth 2.0 library
#require "OAuth2.agent.lib.nut:1.0.0"
// AWS Lambda libraries - are used for RSA-SHA256 signature calculation
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSLambda.agent.lib.nut:1.0.0"

// GooglePubSub.PullSubscriber and GooglePubSub.Subscriptions demo.
// Creates a pull subscription to the specified topic if it does not exist
// (topic name and subscription name are specified as constructor arguments),
// receives messages from it and prints messages data and attributes to the log.
// Messages are received using repeated pending pulls and acknowledged automatically
// using autoAck pull option.
class PullSubscriber {
    _topicName = null;
    _subscrName = null;
    _subscrs = null;
    _pullSubscriber = null;

    constructor(projectId, oAuthTokenProvider, topicName, subscrName) {
        _topicName = topicName;
        _subscrName = subscrName;
        _subscrs = GooglePubSub.Subscriptions(projectId, oAuthTokenProvider);
        _pullSubscriber = GooglePubSub.PullSubscriber(projectId, oAuthTokenProvider, subscrName);
    }

    // Handler function to be executed when messages are received
    function onMessagesReceived(error, messages) {
        if (error) {
            server.error("Pull messages request failed: " + error.details);
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

    // Checks if the specified subscription exists and optionally creates it if not,
    // then receives messages from it using repeated pending pull
    function subscribe() {
        local subscrOptions = {
            "autoCreate" : true,
            "subscrConfig" : GooglePubSub.SubscriptionConfig(_topicName)
        };
        _subscrs.obtain(_subscrName, subscrOptions, function (error, subscrConfig) {
            if (error) {
                server.error("Subscription obtain request failed: " + error.details);
            }
            else {
                local pullOptions = {
                    "repeat" : true,
                    "autoAck" : true
                };
                _pullSubscriber.pendingPull(pullOptions, onMessagesReceived);
            }
        }.bindenv(this));
    }
}

// Configuration constants, substitute with real values
const PROJECT_ID = "...";
const GOOGLE_ISS = "...";
const GOOGLE_SECRET_KEY = "...";
const AWS_LAMBDA_REGION = "...";
const AWS_ACCESS_KEY_ID = "...";
const AWS_SECRET_ACCESS_KEY = "...";

// obtaining OAuth2 Access Tokens Provider
local oAuthTokenProvider = OAuth2.JWTProfile.Client(
    OAuth2.DeviceFlow.GOOGLE,
    {
        "iss"         : GOOGLE_ISS,
        "jwtSignKey"  : GOOGLE_SECRET_KEY,
        "scope"       : "https://www.googleapis.com/auth/pubsub",
        "rs256signer" : AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    });

const TOPIC_NAME = "test_topic";
const SUBSCR_NAME = "test_pull_subscription";

// Start Application
pullSubscriber <- PullSubscriber(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME, SUBSCR_NAME);
pullSubscriber.subscribe();
