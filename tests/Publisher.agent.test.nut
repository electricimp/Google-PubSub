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

const GOOGLE_PROJECT_ID         = "#{env:GOOGLE_PROJECT_ID}";
const GOOGLE_ISS                = "#{env:GOOGLE_ISS}";
const GOOGLE_SECRET_KEY         = "#{env:GOOGLE_SECRET_KEY}";
const AWS_LAMBDA_REGION         = "#{env:AWS_LAMBDA_REGION}";
const AWS_ACCESS_KEY_ID         = "#{env:AWS_ACCESS_KEY_ID}";
const AWS_SECRET_ACCESS_KEY     = "#{env:AWS_SECRET_ACCESS_KEY}";

const TOPIC_NAME_1 = "imptest_topic_1";

// Test case for GooglePubSub.Publisher library
class PublisherTestCase extends ImpTestCase {
    _topics = null;
    _publisher = null;

    // Initializes GooglePubSub.Publisher library
    function setUp() {
        local oAuthTokenProvider = OAuth2.JWTProfile.Client(
            OAuth2.DeviceFlow.GOOGLE,
            {
                "iss"         : GOOGLE_ISS,
                "jwtSignKey"  : GOOGLE_SECRET_KEY,
                "scope"       : "https://www.googleapis.com/auth/pubsub",
                "rs256signer" : AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
            });
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, oAuthTokenProvider);
        _publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, oAuthTokenProvider, TOPIC_NAME_1);
        return Promise(function (resolve, reject) {
            _topics.obtain(TOPIC_NAME_1, { "autoCreate" : true }, function (error) {
                if (error) {
                    return reject(format("topic %s isn't created: %s", TOPIC_NAME_1, error.details));
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    function tearDown() {
        return Promise(function (resolve, reject) {
            _topics.remove(TOPIC_NAME_1, function (error) {
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests Publisher.publish
    function testPublishSimpleMessages() {
        return Promise(function (resolve, reject) {
            local msg1 = "test msg";
            _publisher.publish(msg1, function (error, messageIds) {
                if (error) {
                    return reject("string message not published");
                }
                local msg2 = 12345;
                _publisher.publish(msg2, function (error, messageIds) {
                    if (error) {
                        return reject("int message not published");
                    }
                    local msg3 = { "key1" : "value1", "key2" : 12345 };
                    _publisher.publish(msg3, function (error, messageIds) {
                        if (error) {
                            return reject("table message not published");
                        }
                        local msgArr1 = [msg1, msg2, msg3];
                        _publisher.publish(msgArr1, function (error, messageIds) {
                            if (error) {
                                return reject("messages array not published");
                            }
                            return resolve("");
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests Publisher.publish GooglePubSub.Message messages
    function testPublishMessages() {
        return Promise(function (resolve, reject) {
            local msg1 = GooglePubSub.Message("test msg");
            _publisher.publish(msg1, function (error, messageIds) {
                if (error) {
                    return reject("string message not published");
                }
                local msg2 = GooglePubSub.Message(12345);
                _publisher.publish(msg2, function (error, messageIds) {
                    if (error) {
                        return reject("int message not published");
                    }
                    local msg3 = GooglePubSub.Message({ "key1" : "value1", "key2" : 12345 });
                    _publisher.publish(msg3, function (error, messageIds) {
                        if (error) {
                            return reject("table message not published");
                        }
                        local msgArr1 = [msg1, msg2, msg3];
                        _publisher.publish(msgArr1, function (error, messageIds) {
                            if (error) {
                                return reject("messages array not published");
                            }
                            local msg4 = GooglePubSub.Message(null, {"attr_key1" : "attr_value1", "attr_key2" : "attr_value2"});
                            _publisher.publish(msg4, function (error, messageIds) {
                                if (error) {
                                    return reject("message without data not published");
                                }
                                local msg5 = GooglePubSub.Message(
                                    { "key1" : "value1", "key2" : 12345 },
                                    {"attr_key1" : "attr_value1", "attr_key2" : "attr_value2"});
                                _publisher.publish(msg5, function (error, messageIds) {
                                    if (error) {
                                        return reject("message with data and attrs not published");
                                    }
                                    local msg6 = GooglePubSub.Message(
                                        [msg1, msg2, msg3],
                                        {"attr_key1" : "attr_value1", "attr_key2" : "attr_value2"});
                                    _publisher.publish(msg6, function (error, messageIds) {
                                        if (error) {
                                            return reject("message with array data not published");
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
    }

    function _isLibraryError(error) {
        return error && error.type == PUB_SUB_ERROR.LIBRARY_ERROR;
    }

    // Tests wrong constructor parameters of GooglePubSub.Publisher
    function testWrongLibraryInit() {
        return Promise(function (resolve, reject) {
            local oAuthTokenProvider = OAuth2.JWTProfile.Client(
                OAuth2.DeviceFlow.GOOGLE,
                {
                    "iss"         : GOOGLE_ISS,
                    "jwtSignKey"  : GOOGLE_SECRET_KEY,
                    "scope"       : "https://www.googleapis.com/auth/pubsub",
                    "rs256signer" : AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
                });
            local publisher = GooglePubSub.Publisher(null, oAuthTokenProvider, TOPIC_NAME_1);
            publisher.publish("abc", function (error, messageIds) {
                if (!_isLibraryError(error)) {
                    return reject("null project id accepted");
                }
                publisher = GooglePubSub.Publisher("", oAuthTokenProvider, TOPIC_NAME_1);
                publisher.publish("abc", function (error, messageIds) {
                    if (!_isLibraryError(error)) {
                        return reject("empty project id accepted");
                    }
                    publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, null, TOPIC_NAME_1);
                    publisher.publish("abc", function (error, messageIds) {
                        if (!_isLibraryError(error)) {
                            return reject("null token provider accepted");
                        }
                        publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, oAuthTokenProvider, null);
                        publisher.publish("abc", function (error, messageIds) {
                            if (!_isLibraryError(error)) {
                                return reject("null topic name accepted");
                            }
                            publisher = GooglePubSub.Publisher(GOOGLE_PROJECT_ID, oAuthTokenProvider, "");
                            publisher.publish("abc", function (error, messageIds) {
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

    // Test wrong messages publishing
    function testWrongMessages() {
        return Promise(function (resolve, reject) {
            _publisher.publish(null, function (error, messageIds) {
                if (!_isLibraryError(error)) {
                    return reject("null message accepted");
                }
                _publisher.publish([], function (error, messageIds) {
                    if (!_isLibraryError(error)) {
                        return reject("empty messages array accepted");
                    }
                    _publisher.publish({}, function (error, messageIds) {
                        if (!_isLibraryError(error)) {
                            return reject("empty message table accepted");
                        }
                        _publisher.publish(GooglePubSub.Message(null, null), function (error, messageIds) {
                            if (!_isLibraryError(error)) {
                                return reject("null data and attr accepted");
                            }
                            _publisher.publish(GooglePubSub.Message({}, null), function (error, messageIds) {
                                if (!_isLibraryError(error)) {
                                    return reject("empty data and null attr accepted");
                                }
                                _publisher.publish(GooglePubSub.Message([], null), function (error, messageIds) {
                                    if (!_isLibraryError(error)) {
                                        return reject("empty array data and null attr accepted");
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
}