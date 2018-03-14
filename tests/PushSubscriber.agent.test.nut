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

const TOPIC_NAME_1 = "imptest_push_subscriber_topic_1";
const TOPIC_NAME_2 = "imptest_push_subscriber_topic_2";
const SUBSCR_NAME_1 = "imptest_push_subscriber_subscr_1";
const SUBSCR_NAME_2 = "imptest_push_subscriber_subscr_2";
const SUBSCR_NAME_3 = "imptest_push_subscriber_subscr_3";

// Test case for GooglePubSub.PushSubscriber library
class PushSubscriberTestCase extends CommonTest {
    _publisher = null;
    _publisher2 = null;
    _subscriber = null;
    _subscriber2 = null;

    // Initializes GooglePubSub.Publisher library
    function setUp() {
        _setUp();
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_1);
        _publisher2 = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, _oAuthTokenProvider, TOPIC_NAME_2);
        _subscrs = GooglePubSub.Subscriptions(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _subscriber = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_1);
        _subscriber2 = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_2);
        // clean up topics/subscriptions first
        return tearDown()
            .then(function(value) {
                return Promise.all([
                    _createTopic(TOPIC_NAME_1),
                    _createTopic(TOPIC_NAME_2)
                ]);
            }.bindenv(this))
            .then(function(value) {
                local config1 = GooglePubSub.SubscriptionConfig(
                    TOPIC_NAME_1, 10, GooglePubSub.PushConfig(_subscrs.getImpAgentEndpoint(null, "12345")));
                local config2 = GooglePubSub.SubscriptionConfig(
                    TOPIC_NAME_2, 10, GooglePubSub.PushConfig(_subscrs.getImpAgentEndpoint(null, "12345")));
                local config3 = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1);
                return Promise.all([
                    _createSubscription(SUBSCR_NAME_1, { "autoCreate" : true, "subscrConfig" : config1 }),
                    _createSubscription(SUBSCR_NAME_2, { "autoCreate" : true, "subscrConfig" : config2 }),
                    _createSubscription(SUBSCR_NAME_3, { "autoCreate" : true, "subscrConfig" : config3 })
                ]);
            }.bindenv(this))
            .then(function (value) {
                return _pubSubTimeout();
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function tearDown() {
        return Promise.all([
                _removeSubscription(SUBSCR_NAME_1),
                _removeSubscription(SUBSCR_NAME_2),
                _removeSubscription(SUBSCR_NAME_3)
            ])
            .then(function(value) {
                return Promise.all([
                    _removeTopic(TOPIC_NAME_1),
                    _removeTopic(TOPIC_NAME_2)
                ]);
            }.bindenv(this))
            .then(function (value) {
                return _pubSubTimeout();
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    // Tests messages receiving
    function testMessages() {
        return Promise(function (resolve, reject) {
            local msgsNumber = 5;
            local publisherCounter = 0;
            local subscriberCounter = 0;
            local messagesHandler = function(error, messages) {
                if (error) {
                    return reject("Message error: " + error.details);
                }
                subscriberCounter++;
                if (subscriberCounter == msgsNumber) {
                    return resolve("");
                }
            }
            local publishMessages;
            publishMessages = function() {
                _publisher.publish(publisherCounter, function (error, messageIds) {
                    if (error) {
                        return reject("Message publishing error: " + error.details);
                    }
                    publisherCounter++;
                    if (publisherCounter < msgsNumber) {
                        imp.wakeup(0.5, publishMessages);
                    }
                }.bindenv(this));
            }.bindenv(this);

            _subscriber.setMessagesHandler(messagesHandler, function (error) {
                if (error) {
                    return reject("setMessagesHandler failed: " + error.details);
                }
                publishMessages();
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests messages receiving published simultaneously
    function testMessagesPublishedSimultaneously() {
        return Promise(function (resolve, reject) {
            local msgsNumber = 5;
            local subscriberCounter = 0;
            local messagesHandler = function(error, messages) {
                if (error) {
                    return reject("Message error: " + error.details);
                }
                subscriberCounter++;
                if (subscriberCounter == msgsNumber) {
                    return resolve("");
                }
            }
            _subscriber2.setMessagesHandler(messagesHandler, function (error) {
                if (error) {
                    return reject("setMessagesHandler failed");
                }
                _publisher2.publish([1, 2, 3, 4, 5], function (error, messageIds) {
                    if (error) {
                        return reject("Message publishing error: " + error.details);
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function _isLibraryError(error) {
        return error && error.type == PUB_SUB_ERROR.LIBRARY_ERROR;
    }

    function _messagesHandler(error, messages) {
    }

    // Tests wrong constructor parameters of GooglePubSub.PushSubscriber
    function testWrongLibraryInit() {
        return Promise(function (resolve, reject) {
            local subscriber = GooglePubSub.PushSubscriber(null, _oAuthTokenProvider, SUBSCR_NAME_1);
            subscriber.setMessagesHandler(_messagesHandler, function (error) {
                if (!_isLibraryError(error)) {
                    return reject("null project id accepted");
                }
                subscriber = GooglePubSub.PushSubscriber("", _oAuthTokenProvider, SUBSCR_NAME_1);
                subscriber.setMessagesHandler(_messagesHandler, function (error) {
                    if (!_isLibraryError(error)) {
                        return reject("empty project id accepted");
                    }
                    subscriber = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, null, SUBSCR_NAME_1);
                    subscriber.setMessagesHandler(_messagesHandler, function (error) {
                        if (!_isLibraryError(error)) {
                            return reject("null token provider accepted");
                        }
                        subscriber = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, null);
                        subscriber.setMessagesHandler(_messagesHandler, function (error) {
                            if (!_isLibraryError(error)) {
                                return reject("null topic name accepted");
                            }
                            subscriber = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, "");
                            subscriber.setMessagesHandler(_messagesHandler, function (error) {
                                if (!_isLibraryError(error)) {
                                    return reject("empty topic name accepted");
                                }
                                subscriber = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_1);
                                subscriber.setMessagesHandler(null, function (error) {
                                    if (!_isLibraryError(error)) {
                                        return reject("empty messages handler accepted");
                                    }
                                    return resolve("");
                                }.bindenv(this));
                            }.bindenv(this));
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Test wrong subscription
    function testWrongSubscription() {
        return Promise(function (resolve, reject) {
            local subscriber = GooglePubSub.PushSubscriber(GOOGLE_PROJECT_ID, _oAuthTokenProvider, SUBSCR_NAME_3);
            subscriber.setMessagesHandler(_messagesHandler, function (error) {
                if (!_isLibraryError(error)) {
                    return reject("pull subscription accepted");
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }
}