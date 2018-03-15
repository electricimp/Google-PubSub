// MIT License
//
// Copyright 2017-2018 Electric Imp
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

const TOPIC_NAME_1 = "imptest_topics_topic_1";
const TOPIC_NAME_2 = "imptest_topics_topic_2";
const TOPIC_NAME_3 = "imptest_topics_topic_3";
const TOPIC_NAME_4 = "imptest_topics_topic_4";
const TOPIC_NAME_5 = "imptest_topics_topic_5";

// Test case for GooglePubSub.Topics library
class TopicsTestCase extends CommonTest {

    // Initializes GooglePubSub.Topics library
    function setUp() {
        _setUp();
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        // clean up topics/subscriptions first
        return tearDown()
            .then(function(value) {
                return Promise.all([
                    _createTopic(TOPIC_NAME_2),
                    _createTopic(TOPIC_NAME_3),
                    _createTopic(TOPIC_NAME_4)
                ]);
            }.bindenv(this));
    }

    function tearDown() {
        return Promise.all([
                _removeTopic(TOPIC_NAME_1),
                _removeTopic(TOPIC_NAME_2),
                _removeTopic(TOPIC_NAME_3),
                _removeTopic(TOPIC_NAME_4),
                _removeTopic(TOPIC_NAME_5)
            ]);
    }

    // Tests Topics.obtain
    function testTopicObtain() {
        return _removeTopic(TOPIC_NAME_1)
            .then(function (value) {
                return Promise(function (resolve, reject) {
                    _topics.obtain(TOPIC_NAME_1, null, function (error) {
                        if (!error) {
                            return reject("topic wrongly obtained");
                        }
                        _topics.obtain(TOPIC_NAME_1, { "autoCreate" : false }, function (error) {
                            if (!error) {
                                return reject("topic wrongly obtained");
                            }
                            return resolve("");
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this))
            .then(function (value) {
                return _createTopic(TOPIC_NAME_1);
            }.bindenv(this));
    }

    // Tests Topics.list
    function testTopicList() {
        return Promise(function (resolve, reject) {
            _topics.list(null, function (error, topicNames, nextOptions) {
                if (error) {
                    return reject(format("topic list failed: %s", error.details));
                }
                if (topicNames.find(TOPIC_NAME_3) == null || topicNames.find(TOPIC_NAME_4) == null) {
                    return reject("topic absent in list");
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests paginated Topics.list
    function testTopicPaginatedList() {
        return Promise(function (resolve, reject) {
            local names = [];
            local listCallback = null;
            listCallback = function(error, topicNames, nextOptions) {
                if (error) {
                    return reject(format("topic list failed: %s", error.details));
                }
                names.extend(topicNames);
                if (nextOptions) {
                    _topics.list(nextOptions, listCallback);
                }
                else {
                    if (names.find(TOPIC_NAME_3) == null || names.find(TOPIC_NAME_4) == null) {
                        return reject("topic absent in list");
                    }
                    return resolve("");
                }
            }.bindenv(this);
            _topics.list({ "paginate" : true, "pageSize" : 1 }, listCallback);
        }.bindenv(this));
    }

    // Tests Topics.remove
    function testTopicRemove() {
        return _createTopic(TOPIC_NAME_5)
            .then(function (value) {
                return _removeTopic(TOPIC_NAME_5, true);
            }.bindenv(this))
            .then(function (value) {
                return Promise(function (resolve, reject) {
                    _topics.remove(TOPIC_NAME_5, function (error) {
                        if (!error || error.httpStatus != 404) {
                            return reject("topic remove error");
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this))
    }

    // Tests Topics.iam methods
    function testIam() {
        return Promise(function (resolve, reject) {
            _topics.iam().getPolicy(TOPIC_NAME_2, function (error, policy) {
                if (error) {
                    return reject(format("getPolicy failed: %s", error.details));
                }
                _topics.iam().setPolicy(TOPIC_NAME_2, GooglePubSub.IAM.Policy(0, [], null), function (error, policy) {
                    if (error) {
                        return reject(format("setPolicy failed: %s", error.details));
                    }
                    local permissions = ["pubsub.topics.get", "pubsub.topics.delete"];
                    _topics.iam().testPermissions(TOPIC_NAME_2, permissions, function (error, permissions) {
                        if (error) {
                            return reject(format("testPermissions failed: %s", error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function _isLibraryError(error) {
        return error && error.type == PUB_SUB_ERROR.LIBRARY_ERROR;
    }

    // Tests wrong constructor parameters of GooglePubSub.Topics
    function testInvalidLibraryInit() {
        return Promise(function (resolve, reject) {
            local oAuthTokenProvider = OAuth2.JWTProfile.Client(
                OAuth2.DeviceFlow.GOOGLE,
                {
                    "iss"         : GOOGLE_ISS,
                    "jwtSignKey"  : GOOGLE_SECRET_KEY,
                    "scope"       : "https://www.googleapis.com/auth/pubsub",
                    "rs256signer" : AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
                });
            local topics = GooglePubSub.Topics(null, oAuthTokenProvider);
            topics.remove(TOPIC_NAME_2, function (error) {
                if (!_isLibraryError(error)) {
                    return reject("null project id accepted");
                }
                topics = GooglePubSub.Topics("", oAuthTokenProvider);
                topics.remove(TOPIC_NAME_2, function (error) {
                    if (!_isLibraryError(error)) {
                        return reject("empty project id accepted");
                    }
                    topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, null);
                    topics.remove(TOPIC_NAME_2, function (error) {
                        if (!_isLibraryError(error)) {
                            return reject("null token provider accepted");
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests wrong parameters of Topics methods
    function testInvalidParams() {
        return Promise(function (resolve, reject) {
            _topics.obtain(null, null, function (error) {
                if (!_isLibraryError(error)) {
                    return reject("null topic name in obtain accepted");
                }
                _topics.remove("", function (error) {
                    if (!_isLibraryError(error)) {
                        return reject("empty topic name in remove accepted");
                    }
                    _topics.list({ "paginate" : true, "pageSize" : -1 }, function (error, topicNames, nextOptions) {
                        if (!_isLibraryError(error)) {
                            return reject("negative pageSize in list accepted");
                        }
                        _topics.list({ "paginate" : true, "pageSize" : 0 }, function (error, topicNames, nextOptions) {
                            if (!_isLibraryError(error)) {
                                return reject("zero pageSize in list accepted");
                            }
                            return resolve("");
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests wrong parameters of Topics.iam() methods
    function testInvalidIamParams() {
        return Promise(function (resolve, reject) {
            _topics.iam().getPolicy(null, function (error, policy) {
                if (!_isLibraryError(error)) {
                    return reject("null topic name in iam.getPolicy accepted|" + http.jsonencode(error));
                }
                _topics.iam().setPolicy(null, GooglePubSub.IAM.Policy(), function (error, policy) {
                    if (!_isLibraryError(error)) {
                        return reject("null topic name in iam.setPolicy accepted");
                    }
                    _topics.iam().setPolicy(TOPIC_NAME_2, null, function (error, policy) {
                        if (!_isLibraryError(error)) {
                            return reject("null policy in iam.setPolicy accepted");
                        }
                        _topics.iam().testPermissions(null, [], function (error, perms) {
                            if (!_isLibraryError(error)) {
                                return reject("null topic name in iam.testPermissions accepted");
                            }
                            _topics.iam().testPermissions(TOPIC_NAME_2, [], function (error, perms) {
                                if (!_isLibraryError(error)) {
                                    return reject("empty permissions in iam.testPermissions accepted");
                                }
                                _topics.iam().testPermissions(TOPIC_NAME_2, null, function (error, perms) {
                                    if (!_isLibraryError(error)) {
                                        return reject("null permissions in iam.testPermissions accepted");
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