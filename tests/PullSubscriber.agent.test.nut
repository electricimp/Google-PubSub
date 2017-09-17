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

@include "github:electricimp/AWSRequestV4/AWSRequestV4.class.nut"
@include "github:electricimp/AWSLambda/AWSLambda.agent.lib.nut"
@include "github:electricimp/OAuth-2.0/OAuth2.agent.lib.nut"

const GOOGLE_PROJECT_ID="@{GOOGLE_PROJECT_ID}";
const AWS_LAMBDA_REGION="@{AWS_LAMBDA_REGION}";
const AWS_ACCESS_KEY_ID="@{AWS_ACCESS_KEY_ID}";
const AWS_SECRET_ACCESS_KEY="@{AWS_SECRET_ACCESS_KEY}";
const GOOGLE_ISS="@{GOOGLE_ISS}";
const GOOGLE_SECRET_KEY="@{GOOGLE_SECRET_KEY}";

const TOPIC_NAME_1 = "imptest_topic_1";
const SUBSCR_NAME_1 = "imptest_subscr_1";
const SUBSCR_NAME_2 = "imptest_subscr_2";

// Test case for GooglePubSub.PullSubscriber library
class PullSubscriberTestCase extends ImpTestCase {
    _topics = null;
    _publisher = null;
    _subscrs = null;
    _subscriber = null;
    _oAuthTokenProvider = null;

    // Initializes GooglePubSub.Publisher library
    function setUp() {
        _oAuthTokenProvider = OAuth2.JWTProfile.Client(
            OAuth2.DeviceFlow.GOOGLE,
            {
                "iss"         : GOOGLE_ISS,
                "jwtSignKey"  : GOOGLE_SECRET_KEY,
                "scope"       : "https://www.googleapis.com/auth/pubsub",
                "rs256signer" : AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
            });
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_1);
        _subscrs = GooglePubSub.Subscriptions(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _subscriber = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_1);
        return Promise(function (resolve, reject) {
            _topics.obtain(TOPIC_NAME_1, { "autoCreate" : true }, function (error) {
                if (error) {
                    return reject(format("topic %s isn't created: %s", TOPIC_NAME_1, error.details));
                }
                local config1 = GooglePubSub.SubscriptionConfig(
                    TOPIC_NAME_1, 10, GooglePubSub.PushConfig(_subscrs.getImpAgentEndpoint(null, "12345")));
                _subscrs.obtain(SUBSCR_NAME_2, { "autoCreate" : true, "subscrConfig" : config1 }, function (error, subscrConfig) {
                    if (error) {
                        return reject(format("subscription %s isn't created: %s", SUBSCR_NAME_2, error.details));
                    }
                    local config2 = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1);
                    _subscrs.obtain(SUBSCR_NAME_1, { "autoCreate" : true, "subscrConfig" : config2 }, function (error, subscrConfig) {
                        if (error) {
                            return reject(format("subscription %s isn't created: %s", SUBSCR_NAME_1, error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function tearDown() {
        return Promise(function (resolve, reject) {
            _subscrs.remove(SUBSCR_NAME_1, function (error) {
                _subscrs.remove(SUBSCR_NAME_2, function (error) {
                    _topics.remove(TOPIC_NAME_1, function (error) {
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests pull() method
    function testPull() {
        return Promise(function (resolve, reject) {
            _subscriber.pull({ "autoAck" : true, "maxMessages" : 20 }, function (error, messages) {
                if (error) {
                    return reject("pull error: " + error.details);
                }
                if (messages.len() > 0) {
                    return reject("not empty messages");
                }
                local msgsNumber = 5;
                _publisher.publish(array(msgsNumber, "test"), function (error, messageIds) {
                    if (error) {
                        return reject("publish error: " + error.details);
                    }
                    local messagesReceived = 0;
                    local pull;
                    pull = function() {
                        _subscriber.pull({ "autoAck" : true, "maxMessages" : 2 }, function (error, messages) {
                            if (error) {
                                return reject("pull error: " + error.details);
                            }
                            messagesReceived += messages.len();
                            if (messagesReceived == msgsNumber) {
                                return resolve("");
                            }
                            else if (messagesReceived < msgsNumber) {
                                imp.wakeup(1.0, pull);
                            }
                            else {
                                return reject("wrong number of messages");
                            }
                        }.bindenv(this));
                    }.bindenv(this);
                    pull();
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests periodicPull() method
    function testPeriodicPull() {
        return Promise(function (resolve, reject) {
            local msgsNumber = 10;
            local messagesReceived = 0;
            _subscriber.periodicPull(2.0, { "autoAck" : true, "maxMessages" : 3 }, function (error, messages) {
                if (error) {
                    _subscriber.stopPull();
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    _subscriber.stopPull();
                    return reject("return empty messages");
                }
                messagesReceived += messages.len();
                if (messagesReceived == msgsNumber) {
                    _subscriber.stopPull();
                    return resolve("");
                }
                else if (messagesReceived > msgsNumber) {
                    _subscriber.stopPull();
                    return reject("wrong number of messages");
                }
            }.bindenv(this));

            imp.wakeup(10.0, function() {
                _publisher.publish(array(msgsNumber, "test"), function (error, messageIds) {
                    if (error) {
                        _subscriber.stopPull();
                        return reject("publish error: " + error.details);
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests pendingPull() method
    function testPendingPull() {
        return Promise(function (resolve, reject) {
            _subscriber.pendingPull({ "autoAck" : true, "maxMessages" : 20 }, function (error, messages) {
                if (error) {
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    return reject("return empty messages");
                }
                else {
                    return resolve("");
                }
            }.bindenv(this));
            // this huge value is needed to check that pending pull is restored after timeout
            imp.wakeup(100.0, function() {
                _publisher.publish("test", function (error, messageIds) {
                    if (error) {
                        return reject("publish error: " + error.details);
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests repeated pendingPull() method
    function testRepeatedPendingPull() {
        return Promise(function (resolve, reject) {
            local msgsNumber = 10;
            local messagesReceived = 0;
            local pendingPull;
            _subscriber.pendingPull({ "repeat" : true, "autoAck" : true, "maxMessages" : 1 }, function (error, messages) {
                if (error) {
                    _subscriber.stopPull();
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    _subscriber.stopPull();
                    return reject("return empty messages");
                }
                messagesReceived += messages.len();
                if (messagesReceived == msgsNumber) {
                    _subscriber.stopPull();
                    return resolve("");
                }
                else if (messagesReceived > msgsNumber) {
                    _subscriber.stopPull();
                    return reject("wrong number of messages");
                }
            }.bindenv(this));

            local messagesSent = 0;
            local publish;
            publish = function () {
                _publisher.publish("test", function (error, messageIds) {
                    if (error) {
                        _subscriber.stopPull();
                        return reject("publish error: " + error.details);
                    }
                    messagesSent++;
                }.bindenv(this));

                if (messagesSent < msgsNumber) {
                    imp.wakeup(5.0, publish);
                }
            }.bindenv(this);
            publish();
        }.bindenv(this));
    }

    // Tests ack() and modifyAckDeadline() method
    function testAck() {
        return Promise(function (resolve, reject) {
            local msgsNumber = 5;
            local messagesReceived = 0;
            local order = 0;
            _subscriber.periodicPull(2.0, { "autoAck" : false, "maxMessages" : 1 }, function (error, messages) {
                if (error) {
                    _subscriber.stopPull();
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    _subscriber.stopPull();
                    return reject("return empty messages");
                }
                messagesReceived += messages.len();
                local ackMessages = null;
                switch (order) {
                    case 0 :
                        ackMessages = messages.map(function (value) { return value.ackId; });
                        break;
                    case 1 :
                        ackMessages = messages[0].ackId;
                        break;
                    case 2 :
                        ackMessages = messages[0];
                        break;
                    default :
                        ackMessages = messages;
                        break;
                }
                order++;
                _subscriber.modifyAckDeadline(ackMessages, 15, function (error) {
                    if (error) {
                        _subscriber.stopPull();
                        return reject("modifyAckDeadline error: " + error.details);
                    }
                    _subscriber.ack(ackMessages, function (error) {
                        if (error) {
                            _subscriber.stopPull();
                            return reject("ack error: " + error.details);
                        }
                        if (messagesReceived == msgsNumber) {
                            _subscriber.stopPull();
                            return resolve("");
                        }
                        else if (messagesReceived > msgsNumber) {
                            _subscriber.stopPull();
                            return reject("wrong number of messages");
                        }
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));

            _publisher.publish(array(msgsNumber, "test"), function (error, messageIds) {
                if (error) {
                    _subscriber.stopPull();
                    return reject("publish error: " + error.details);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests stopPull() method
    function testStopPull() {
         return Promise(function (resolve, reject) {
            _subscriber.periodicPull(2.0, null, function (error, messages) {});

            _subscriber.pull(null, function (error, messages) {
                if (!_isLibraryError(error)) {
                    _subscriber.stopPull();
                    return reject("second active pull accepted");
                }
                imp.wakeup(5, function () {
                    _subscriber.stopPull();
                    _subscriber.pull(null, function (error, messages) {
                        if (error) {
                            return reject("stopPull failed");
                        }
                        _subscriber.pendingPull({"repeat" : true}, function (error, messages) {});
                        imp.wakeup(5, function () {
                            _subscriber.periodicPull(2.0, null, function (error, messages) {
                                if (!_isLibraryError(error)) {
                                    _subscriber.stopPull();
                                    return reject("second active pull with pending accepted");
                                }
                                imp.wakeup(5, function () {
                                    _subscriber.stopPull();
                                    _subscriber.pull(null, function (error, messages) {
                                        if (error) {
                                            return reject("pending stopPull failed");
                                        }
                                        _subscriber.stopPull();
                                        return resolve("");
                                    }.bindenv(this));
                                }.bindenv(this));
                            }.bindenv(this));
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function _isLibraryError(error) {
        return error && error.type == PUB_SUB_ERROR.LIBRARY_ERROR;
    }

    // Tests wrong constructor parameters of GooglePubSub.PullSubscriber
    function testWrongLibraryInit() {
        return Promise(function (resolve, reject) {
            local subscriber = GooglePubSub.PullSubscriber(null, _oAuthTokenProvider, SUBSCR_NAME_1);
            subscriber.pull(null, function (error, messages) {
                if (!_isLibraryError(error)) {
                    return reject("null project id accepted");
                }
                subscriber = GooglePubSub.PullSubscriber("", _oAuthTokenProvider, SUBSCR_NAME_1);
                subscriber.pull(null, function (error, messages) {
                    if (!_isLibraryError(error)) {
                        return reject("empty project id accepted");
                    }
                    subscriber = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, null, SUBSCR_NAME_1);
                    subscriber.pull(null, function (error, messages) {
                        if (!_isLibraryError(error)) {
                            return reject("null token provider accepted");
                        }
                        subscriber = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, null);
                        subscriber.pull(null, function (error, messages) {
                            if (!_isLibraryError(error)) {
                                return reject("null topic name accepted");
                            }
                            subscriber = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, "");
                            subscriber.pull(null, function (error, messages) {
                                if (!_isLibraryError(error)) {
                                    return reject("empty topic name accepted");
                                }
                                return resolve("");
                            }.bindenv(this));
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function testWrongParams() {
         return Promise(function (resolve, reject) {
            _subscriber.pull({ "maxMessages" : 0 }, function (error, messages) {
                if (!_isLibraryError(error)) {
                    return reject("zero maxMessages accepted");
                }
                _subscriber.pendingPull({ "maxMessages" : -1 }, function (error, messages) {
                    if (!_isLibraryError(error)) {
                        return reject("negative maxMessages accepted");
                    }
                    _subscriber.periodicPull(0, null, function (error, messages) {
                        if (!_isLibraryError(error)) {
                            return reject("zero peroid accepted");
                        }
                        _subscriber.periodicPull(-5.0, null, function (error, messages) {
                            if (!_isLibraryError(error)) {
                                return reject("negative peroid accepted");
                            }
                            _subscriber.ack(null, function (error) {
                                if (!_isLibraryError(error)) {
                                    return reject("null ack message accepted");
                                }
                                _subscriber.ack([], function (error) {
                                    if (!_isLibraryError(error)) {
                                        return reject("empty array ack messages accepted");
                                    }
                                    _subscriber.modifyAckDeadline(null, 10, function (error) {
                                        if (!_isLibraryError(error)) {
                                            return reject("null modifyAckDeadline message accepted");
                                        }
                                        _subscriber.modifyAckDeadline(null, -7.0, function (error) {
                                            if (!_isLibraryError(error)) {
                                                return reject("negative ackDeadline accepted");
                                            }
                                            return resolve("");
                                        }.bindenv(this));
                                    }.bindenv(this));
                                }.bindenv(this));
                            }.bindenv(this));
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }
}