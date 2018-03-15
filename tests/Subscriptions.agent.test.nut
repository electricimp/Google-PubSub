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

const TOPIC_NAME_1 = "imptest_subscriptions_topic_1";
const SUBSCR_NAME_1 = "imptest_subscriptions_subscr_1";
const SUBSCR_NAME_2 = "imptest_subscriptions_subscr_2";
const SUBSCR_NAME_3 = "imptest_subscriptions_subscr_3";
const SUBSCR_NAME_4 = "imptest_subscriptions_subscr_4";
const SUBSCR_NAME_5 = "imptest_subscriptions_subscr_5";

// Test case for GooglePubSub.Subscriptions library
class SubscriptionsTestCase extends CommonTest {

    // Initializes GooglePubSub.Subscriptions library
    function setUp() {
        _setUp();
        _subscrs = GooglePubSub.Subscriptions(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, _oAuthTokenProvider);
        // clean up topics/subscriptions first
        return tearDown()
            .then(function (value) {
                return _createTopic(TOPIC_NAME_1);
            }.bindenv(this))
            .then(function (value) {
                local config = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1, 10, null);
                return _createSubscription(SUBSCR_NAME_2, { "autoCreate" : true, "subscrConfig" : config });
            }.bindenv(this))
            .then(function (value) {
                local config = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1);
                return _createSubscription(SUBSCR_NAME_3, { "autoCreate" : true, "subscrConfig" : config });
            }.bindenv(this))
            .then(function (value) {
                return _createSubscription(SUBSCR_NAME_4, { "autoCreate" : true, "subscrConfig" : GooglePubSub.SubscriptionConfig(TOPIC_NAME_1) });
            }.bindenv(this))
            .then(function (value) {
                return _pubSubDelay();
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function tearDown() {
        return Promise.all([
                _removeSubscription(SUBSCR_NAME_1),
                _removeSubscription(SUBSCR_NAME_2),
                _removeSubscription(SUBSCR_NAME_3),
                _removeSubscription(SUBSCR_NAME_4),
                _removeSubscription(SUBSCR_NAME_5)
            ])
            .then(function (value) {
                return _removeTopic(TOPIC_NAME_1);
            }.bindenv(this))
            .then(function (value) {
                return _pubSubDelay();
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    // Tests Subscriptions.obtain
    function testSubscriptionObtain() {
        return _removeSubscription(SUBSCR_NAME_1)
            .then(function (value) {
                return _pubSubDelay();
            }.bindenv(this))
            .then(function (value) {
                return Promise(function (resolve, reject) {
                    _subscrs.obtain(SUBSCR_NAME_1, null, function (error, subscrConfig) {
                        if (!error) {
                            return reject("subscription wrongly obtained");
                        }
                        _subscrs.obtain(SUBSCR_NAME_1, { "autoCreate" : false }, function (error, subscrConfig) {
                            if (!error) {
                                return reject("subscription wrongly obtained");
                            }
                            local config = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1, 20, null);
                            _subscrs.obtain(SUBSCR_NAME_1, { "autoCreate" : true, "subscrConfig" : config }, function (error, subscrConfig) {
                                if (error) {
                                    return reject(format("subscription %s isn't created: %s", SUBSCR_NAME_1, error.details));
                                }
                                if (config.topicName != subscrConfig.topicName ||
                                    config.ackDeadlineSeconds != subscrConfig.ackDeadlineSeconds ||
                                    config.pushConfig != config.pushConfig) {
                                    return reject("wrong subscription config");
                                }
                                return resolve("");
                            }.bindenv(this));
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function _subscrListTest(topicName = null) {
        return Promise(function (resolve, reject) {
            _subscrs.list({ "paginate" : false, "topicName" : topicName }, function (error, names, nextOptions) {
                if (error) {
                    return reject(format("subscription list failed: %s", error.details));
                }
                if (names.find(SUBSCR_NAME_3) == null || names.find(SUBSCR_NAME_4) == null) {
                    return reject("subscription absent in list");
                }
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests Subscriptions.list
    function testSubscriptionList() {
        return _subscrListTest();
    }

    // Tests Subscriptions.list with topic specified
    function testSubscriptionListWithTopic() {
        return _subscrListTest(TOPIC_NAME_1);
    }

    function _paginatedListTest(topicName = null) {
        return Promise(function (resolve, reject) {
            local names = [];
            local listCallback = null;
            listCallback = function(error, subscrNames, nextOptions) {
                if (error) {
                    return reject(format("subscription list failed: %s", error.details));
                }
                names.extend(subscrNames);
                if (nextOptions) {
                    _subscrs.list(nextOptions, listCallback);
                }
                else {
                    if (names.find(SUBSCR_NAME_3) == null || names.find(SUBSCR_NAME_4) == null) {
                        return reject("subscription absent in list");
                    }
                    return resolve("");
                }
            }.bindenv(this);
            _subscrs.list({ "paginate" : true, "pageSize" : 1, "topicName" : topicName }, listCallback);
        }.bindenv(this));
    }

    // Tests paginated Subscriptions.list
    function testSubscriptionPaginatedList() {
        return _paginatedListTest();
    }

    // Tests paginated Subscriptions.list with topic specified
    function testSubscriptionPaginatedListWithTopic() {
        return _paginatedListTest(TOPIC_NAME_1);
    }

    // Tests Subscriptions.remove
    function testSubscriptionRemove() {
        local config = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1, 10, null);
        return _createSubscription(SUBSCR_NAME_5, { "autoCreate" : true, "subscrConfig" : config })
            .then(function (value) {
                return _pubSubDelay();
            }.bindenv(this))
            .then(function (value) {
                return _removeSubscription(SUBSCR_NAME_5, true);
            }.bindenv(this))
            .then(function (value) {
                return _pubSubDelay();
            }.bindenv(this))
            .then(function (value) {
                return Promise(function (resolve, reject) {
                    _subscrs.remove(SUBSCR_NAME_5, function (error) {
                        if (!error || error.httpStatus != 404) {
                            return reject("subscriptions remove error");
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this))
            .fail(function (reason) {
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function testModifyPushConfig() {
        return Promise(function (resolve, reject) {
            _subscrs.modifyPushConfig(SUBSCR_NAME_2, GooglePubSub.PushConfig(_subscrs.getImpAgentEndpoint()), function(error) {
                if (error) {
                    return reject(format("push config modification failed: %s", error.details));
                }
                _subscrs.modifyPushConfig(SUBSCR_NAME_2, null, function(error) {
                    if (error) {
                        return reject(format("modification push config to null failed: %s", error.details));
                    }
                    return resolve("");
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests Subscriptions.iam methods
    function testIam() {
        return Promise(function (resolve, reject) {
            _subscrs.iam().getPolicy(SUBSCR_NAME_2, function (error, policy) {
                if (error) {
                    return reject(format("getPolicy failed: %s", error.details));
                }
                _subscrs.iam().setPolicy(SUBSCR_NAME_2, GooglePubSub.IAM.Policy(0, [], null), function (error, policy) {
                    if (error) {
                        return reject(format("setPolicy failed: %s", error.details));
                    }
                    local permissions = ["pubsub.subscriptions.get", "pubsub.subscriptions.delete"];
                    _subscrs.iam().testPermissions(SUBSCR_NAME_2, permissions, function (error, permissions) {
                        if (error) {
                            return reject(format("testPermissions failed: %s", error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }
}