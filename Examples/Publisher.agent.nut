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

// GooglePubSub.Publisher and GooglePubSub.Topics demo.
// Creates a topic if it does not exist (topic name is specified as constructor argument)
// and periodically publishes messages to the topic.
// Messages are published every 10 seconds, every message contains integer increasing data 
// and measureTime attribute with data measurement time in seconds since the epoch format.
class Publisher {
    _topicName = null;
    _topics = null;
    _publisher = null;
    _counter = 0;

    constructor(projectId, oAuthTokenProvider, topicName) {
        _topicName = topicName;
        _topics = GooglePubSub.Topics(projectId, oAuthTokenProvider);
        _publisher = GooglePubSub.Publisher(projectId, oAuthTokenProvider, topicName);
    }

    // Returns a message to be published
    function getData() {
        _counter++;
        return GooglePubSub.Message(_counter, { "measureTime" : time().tostring() });
    }

    // Periodically publishes messages to the specified topic
    function publishData() {
        _publisher.publish(getData(), function (error, messageIds) {
            if (error) {
                server.error("Publish request failed: " + error.details);
            }
            else {
                server.log("Data published successfully");
            }
        });
        imp.wakeup(10.0, function () {
            publishData();
        }.bindenv(this));
    }

    // Checks if the specified topic exists and optionally creates it if not,
    // then periodically publishes messages to the topic
    function publish() {
        _topics.obtain(_topicName, { "autoCreate" : true }, function (error) {
            if (error) {
                server.error("Topic obtain request failed: " + error.details);
            }
            else {
                publishData();
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

// Start Application
publisher <- Publisher(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME);
publisher.publish();
