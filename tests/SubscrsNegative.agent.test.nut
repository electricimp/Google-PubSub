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

@include "https://raw.githubusercontent.com/electricimp/AWSRequestV4/master/AWSRequestV4.class.nut"
@include "https://raw.githubusercontent.com/electricimp/AWSLambda/master/AWSLambda.agent.lib.nut"
@include "https://raw.githubusercontent.com/electricimp/OAuth-2.0/master/OAuth2.agent.lib.nut"

const GOOGLE_PROJECT_ID="@{GOOGLE_PROJECT_ID}";
const AWS_LAMBDA_REGION="@{AWS_LAMBDA_REGION}";
const AWS_ACCESS_KEY_ID="@{AWS_ACCESS_KEY_ID}";
const AWS_SECRET_ACCESS_KEY="@{AWS_SECRET_ACCESS_KEY}";
const GOOGLE_ISS="@{GOOGLE_ISS}";
const GOOGLE_SECRET_KEY="@{GOOGLE_SECRET_KEY}";

const TOPIC_NAME_1 = "imptest_topic_1";
const SUBSCR_NAME_1 = "imptest_subscr_1";

// Test case for GooglePubSub.Subscriptions library
class SubscrsNegativeTestCase extends ImpTestCase {
    _topics = null;
    _subscrs = null;

    // Initializes GooglePubSub.Subscriptions library
    function setUp() {
        local oAuthTokenProvider = OAuth2.JWTProfile.Client(
            OAuth2.DeviceFlow.GOOGLE,
            {
                "iss"         : GOOGLE_ISS,
                "jwtSignKey"  : GOOGLE_SECRET_KEY,
                "scope"       : "https://www.googleapis.com/auth/pubsub",
                "rs256signer" : AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
            });
        _subscrs = GooglePubSub.Subscriptions(GOOGLE_PROJECT_ID, oAuthTokenProvider);
        _topics = GooglePubSub.Topics(GOOGLE_PROJECT_ID, oAuthTokenProvider);
        // clean up topics/subscriptions first
        return tearDown().then(function(value) {
            return Promise(function (resolve, reject) {
                _topics.obtain(TOPIC_NAME_1, { "autoCreate" : true }, function (error) {
                    if (error) {
                        return reject(format("topic %s isn't created: %s", TOPIC_NAME_1, error.details));
                    }
                    imp.wakeup(5.0, function() {
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function tearDown() {
        return Promise(function (resolve, reject) {
            _subscrs.remove(SUBSCR_NAME_1, function (error) {
                _topics.remove(TOPIC_NAME_1, function (error) {
                    return resolve("");
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    function _isLibraryError(error) {
        return error && error.type == PUB_SUB_ERROR.LIBRARY_ERROR;
    }

    // Tests wrong constructor parameters of GooglePubSub.Subscriptions
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
            local subscrs = GooglePubSub.Subscriptions(null, oAuthTokenProvider);
            subscrs.remove(SUBSCR_NAME_1, function (error) {
                if (!_isLibraryError(error)) {
                    return reject("null project id accepted");
                }
                subscrs = GooglePubSub.Subscriptions("", oAuthTokenProvider);
                subscrs.remove(SUBSCR_NAME_1, function (error) {
                    if (!_isLibraryError(error)) {
                        return reject("empty project id accepted");
                    }
                    subscrs = GooglePubSub.Subscriptions(GOOGLE_PROJECT_ID, null);
                    subscrs.remove(SUBSCR_NAME_1, function (error) {
                        if (!_isLibraryError(error)) {
                            return reject("null token provider accepted");
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests wrong parameters of Subscriptions methods
    function testWrongParams() {
        return Promise(function (resolve, reject) {
            _subscrs.obtain("", null, function (error, subscrConfig) {
                if (!_isLibraryError(error)) {
                    return reject("empty subscription name in obtain accepted");
                }
                local config = GooglePubSub.SubscriptionConfig(TOPIC_NAME_1, 10, GooglePubSub.PushConfig(null));
                _subscrs.obtain(SUBSCR_NAME_1, {"autoCreate" : true, "subscrConfig" : config}, function (error, subscrConfig) {
                    if (!_isLibraryError(error)) {
                        return reject("empty push config endpoint accepted");
                    }
                    _subscrs.remove(null, function (error) {
                        if (!_isLibraryError(error)) {
                            return reject("null subscription name in remove accepted");
                        }
                        _subscrs.list({ "paginate" : true, "pageSize" : -1 }, function (error, names, nextOptions) {
                            if (!_isLibraryError(error)) {
                                return reject("negative pageSize in list accepted");
                            }
                            _subscrs.list({ "paginate" : true, "pageSize" : 0 }, function (error, names, nextOptions) {
                                if (!_isLibraryError(error)) {
                                    return reject("zero pageSize in list accepted");
                                }
                                return resolve("");
                            }.bindenv(this));
                        }.bindenv(this));
                    }.bindenv(this));
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    // Tests wrong parameters of Subscriptions.iam() methods
    function testWrongIamParams() {
        return Promise(function (resolve, reject) {
            _subscrs.iam().getPolicy(null, function (error, policy) {
                if (!_isLibraryError(error)) {
                    return reject("null subscription name in iam.getPolicy accepted|" + http.jsonencode(error));
                }
                _subscrs.iam().setPolicy(null, GooglePubSub.IAM.Policy(), function (error, policy) {
                    if (!_isLibraryError(error)) {
                        return reject("null subscription name in iam.setPolicy accepted");
                    }
                    _subscrs.iam().setPolicy(SUBSCR_NAME_1, null, function (error, policy) {
                        if (!_isLibraryError(error)) {
                            return reject("null policy in iam.setPolicy accepted");
                        }
                        _subscrs.iam().testPermissions(null, [], function (error, perms) {
                            if (!_isLibraryError(error)) {
                                return reject("null subscription name in iam.testPermissions accepted");
                            }
                            _subscrs.iam().testPermissions(SUBSCR_NAME_1, [], function (error, perms) {
                                if (!_isLibraryError(error)) {
                                    return reject("empty permissions in iam.testPermissions accepted");
                                }
                                _subscrs.iam().testPermissions(SUBSCR_NAME_1, null, function (error, perms) {
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