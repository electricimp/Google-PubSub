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

@include "./tests/CommonTest.nut"

const TOPIC_NAME_1 = "imptest_pull_subscriber_topic_1";
const TOPIC_NAME_2 = "imptest_pull_subscriber_topic_2";
const TOPIC_NAME_3 = "imptest_pull_subscriber_topic_3";
const TOPIC_NAME_4 = "imptest_pull_subscriber_topic_4";
const TOPIC_NAME_5 = "imptest_pull_subscriber_topic_5";
const SUBSCR_NAME_1 = "imptest_pull_subscriber_subscr_1";
const SUBSCR_NAME_2 = "imptest_pull_subscriber_subscr_2";
const SUBSCR_NAME_3 = "imptest_pull_subscriber_subscr_3";
const SUBSCR_NAME_4 = "imptest_pull_subscriber_subscr_4";
const SUBSCR_NAME_5 = "imptest_pull_subscriber_subscr_5";

// Test case for GooglePubSub.PullSubscriber library
class PullSubscriberTestCase extends CommonTest {
    _publisher = null;
    _publisher2 = null;
    _publisher3 = null;
    _publisher4 = null;
    _publisher5 = null;
    _subscriber = null;
    _subscriber2 = null;
    _subscriber3 = null;
    _subscriber4 = null;
    _subscriber5 = null;

    // Initializes GooglePubSub.Publisher library
    function setUp() {
        _setUp();
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _subscrs = GooglePubSub.Subscriptions(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_1);
        _publisher2 = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_2);
        _publisher3 = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_3);
        _publisher4 = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_4);
        _publisher5 = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_5);
        _subscriber = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_1);
        _subscriber2 = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_2);
        _subscriber3 = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_3);
        _subscriber4 = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_4);
        _subscriber5 = GooglePubSub.PullSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_5);
        // clean up topics/subscriptions first
        return tearDown().
            then(function(value) {
                    return Promise.all([
                        _createTopicAndSubscription(TOPIC_NAME_1, SUBSCR_NAME_1),
                        _createTopicAndSubscription(TOPIC_NAME_2, SUBSCR_NAME_2),
                        _createTopicAndSubscription(TOPIC_NAME_3, SUBSCR_NAME_3),
                        _createTopicAndSubscription(TOPIC_NAME_4, SUBSCR_NAME_4),
                        _createTopicAndSubscription(TOPIC_NAME_5, SUBSCR_NAME_5)
                    ]);
                }.bindenv(this)).
            then(function(value) {
                    return _pubSubTimeout();
                }.bindenv(this)).
            fail(function(reason) {
                    return Promise.reject(reason);
                }.bindenv(this));
    }

    function _createTopicAndSubscription(topicName, subscrName) {
        return _createTopic(topicName)
            .then(function(value) {
                local config = GooglePubSub.SubscriptionConfig(topicName);
                return _createSubscription(subscrName, { "autoCreate" : true, "subscrConfig" : config });
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function tearDown() {
        return _removeSubscrs().
            then(function(value) {
                    return _removeTopics();
                }.bindenv(this)).
            then(function(value) {
                    return _pubSubTimeout();
                }.bindenv(this)).
            fail(function(reason) {
                    return Promise.reject(reason);
                }.bindenv(this)
            );
    }

    function _removeTopics() {
        return Promise.all([
                _removeTopic(TOPIC_NAME_1),
                _removeTopic(TOPIC_NAME_2),
                _removeTopic(TOPIC_NAME_3),
                _removeTopic(TOPIC_NAME_4),
                _removeTopic(TOPIC_NAME_5)
            ]);
    }

    function _removeSubscrs() {
        return Promise.all([
                _removeSubscription(SUBSCR_NAME_1),
                _removeSubscription(SUBSCR_NAME_2),
                _removeSubscription(SUBSCR_NAME_3),
                _removeSubscription(SUBSCR_NAME_4),
                _removeSubscription(SUBSCR_NAME_5)
            ]);
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
            _subscriber2.periodicPull(2.0, { "autoAck" : true, "maxMessages" : 3 }, function (error, messages) {
                if (error) {
                    _subscriber2.stopPull();
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    _subscriber2.stopPull();
                    return reject("return empty messages");
                }
                messagesReceived += messages.len();
                if (messagesReceived == msgsNumber) {
                    _subscriber2.stopPull();
                    return resolve("");
                }
                else if (messagesReceived > msgsNumber) {
                    _subscriber2.stopPull();
                    return reject("wrong number of messages");
                }
            }.bindenv(this));

            imp.wakeup(10.0, function() {
                _publisher2.publish(array(msgsNumber, "test"), function (error, messageIds) {
                    if (error) {
                        _subscriber2.stopPull();
                        return reject("publish error: " + error.details);
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests pendingPull() method
    function testPendingPull() {
        return Promise(function (resolve, reject) {
            _subscriber3.pendingPull({ "autoAck" : true, "maxMessages" : 20 }, function (error, messages) {
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
                _publisher3.publish("test", function (error, messageIds) {
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
            _subscriber4.pendingPull({ "repeat" : true, "autoAck" : true, "maxMessages" : 1 }, function (error, messages) {
                if (error) {
                    _subscriber4.stopPull();
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    _subscriber4.stopPull();
                    return reject("return empty messages");
                }
                messagesReceived += messages.len();
                if (messagesReceived == msgsNumber) {
                    _subscriber4.stopPull();
                    return resolve("");
                }
                else if (messagesReceived > msgsNumber) {
                    _subscriber4.stopPull();
                    return reject("wrong number of messages");
                }
            }.bindenv(this));

            local messagesSent = 0;
            local publish;
            publish = function () {
                _publisher4.publish("test", function (error, messageIds) {
                    if (error) {
                        _subscriber4.stopPull();
                        return reject("publish error: " + error.details);
                    }
                    messagesSent++;
                    if (messagesSent < msgsNumber) {
                        imp.wakeup(5.0, publish);
                    }
                }.bindenv(this));
            }.bindenv(this);
            imp.wakeup(5.0, function() {
                publish();
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests ack() and modifyAckDeadline() method
    function testAck() {
        return Promise(function (resolve, reject) {
            local msgsNumber = 5;
            local messagesReceived = 0;
            local order = 0;
            _subscriber5.periodicPull(2.0, { "autoAck" : false, "maxMessages" : 1 }, function (error, messages) {
                if (error) {
                    _subscriber5.stopPull();
                    return reject("pull error: " + error.details);
                }
                if (messages.len() == 0) {
                    _subscriber5.stopPull();
                    return reject("return empty messages");
                }
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
                _subscriber5.modifyAckDeadline(ackMessages, 15, function (error) {
                    if (error) {
                        _subscriber5.stopPull();
                        return reject("modifyAckDeadline error: " + error.details);
                    }
                    _subscriber5.ack(ackMessages, function (error) {
                        messagesReceived += messages.len();
                        if (error) {
                            _subscriber5.stopPull();
                            return reject("ack error: " + error.details);
                        }
                        if (messagesReceived == msgsNumber) {
                            _subscriber5.stopPull();
                            return resolve("");
                        }
                        else if (messagesReceived > msgsNumber) {
                            _subscriber5.stopPull();
                            return reject("wrong number of messages");
                        }
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));

            imp.wakeup(5.0, function() {
                _publisher5.publish(array(msgsNumber, "test"), function (error, messageIds) {
                    if (error) {
                        _subscriber5.stopPull();
                        return reject("publish error: " + error.details);
                    }
                }.bindenv(this));
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
                imp.wakeup(2.0, function () {
                    _subscriber.stopPull();
                    imp.wakeup(2.0, function () {
                        _subscriber.pull(null, function (error, messages) {
                            if (error) {
                                return reject("stopPull failed");
                            }
                            _subscriber.pendingPull({"repeat" : true}, function (error, messages) {});
                            imp.wakeup(2.0, function () {
                                _subscriber.periodicPull(2.0, null, function (error, messages) {
                                    if (!_isLibraryError(error)) {
                                        _subscriber.stopPull();
                                        return reject("second active pull with pending accepted");
                                    }
                                    imp.wakeup(2.0, function () {
                                        _subscriber.stopPull();
                                        imp.wakeup(2.0, function () {
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
