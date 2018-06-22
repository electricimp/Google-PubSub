// MIT License
//
// Copyright 2018 Electric Imp
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

@include "https://raw.githubusercontent.com/electricimp/OAuth-2.0/master/OAuth2.agent.lib.nut"

const GOOGLE_PROJECT_ID = "@{GOOGLE_PROJECT_ID}";
const GOOGLE_ISS = "@{GOOGLE_ISS}";
const GOOGLE_SECRET_KEY = "@{GOOGLE_SECRET_KEY}";

const GOOGLE_PUB_SUB_DELAY_SEC = 3.0;

class CommonTest extends ImpTestCase {
    _topics = null;
    _subscrs = null;
    _oAuthTokenProvider = null;

    function _setUp() {
        _oAuthTokenProvider = OAuth2.JWTProfile.Client(
            OAuth2.DeviceFlow.GOOGLE,
            {
                "iss"         : GOOGLE_ISS,
                "jwtSignKey"  : GOOGLE_SECRET_KEY,
                "scope"       : "https://www.googleapis.com/auth/pubsub"
            });
    }

    function _removeTopic(topicName, checkError = false) {
        return Promise(function (resolve, reject) {
                    _topics.remove(topicName, function (error) {
                        if (error && checkError) {
                            return reject(format("topic %s removing failed: %s", topicName, error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this))
            .then(function (value) {
                return _checkEntityStatus(topicName, true, false);
            }.bindenv(this))
    }

    function _createTopic(topicName) {
        return Promise(function (resolve, reject) {
                    _topics.obtain(topicName, { "autoCreate" : true }, function (error) {
                        if (error) {
                            return reject(format("topic %s isn't created: %s", topicName, error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this))
            .then(function (value) {
                return _checkEntityStatus(topicName, true, true);
            }.bindenv(this));
    }

    function _removeSubscription(subscrName, checkError = false) {
        return Promise(function (resolve, reject) {
                    _subscrs.remove(subscrName, function (error) {
                        if (error && checkError) {
                            return reject(format("subscription %s removing failed: %s", topicName, error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this))
            .then(function (value) {
                return _checkEntityStatus(subscrName, false, false);
            }.bindenv(this))
    }

    function _createSubscription(subscrName, options) {
        return Promise(function (resolve, reject) {
                    _subscrs.obtain(subscrName, options, function (error, subscrConfig) {
                        if (error) {
                            return reject(format("subscription %s isn't created: %s", subscrName, error.details));
                        }
                        return resolve("");
                    }.bindenv(this));
                }.bindenv(this))
            .then(function (value) {
                return _checkEntityStatus(subscrName, false, true);
            }.bindenv(this));
    }

    // Sometimes the Google PubSub service requires significant time to actually process a request (eg. create/delete Topic or Subscription),
    // even after the successful response was already received.
    // This function periodically checks the created/deleted entity existence and resolves when it is actually created/deleted.
    function _checkEntityStatus(entityName, isTopic, checkEntityExists) {
        local checked = false;
        local statusChecker = function(error, resolve, reject) {
            if (!error) {
                if (checkEntityExists) {
                    checked = true;
                }
                resolve("");
            }
            else if (error.type == PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED &&
                error.httpStatus == 404) {
                if (!checkEntityExists) {
                    checked = true;
                }
                resolve("");
            }
            else {
                reject(error);
            }
        }
        return Promise.loop(
            function() {
                return !checked;
            }.bindenv(this),
            function () {
                return _pubSubDelay()
                    .then(function (value) {
                        return Promise(function (resolve, reject) {
                            if (isTopic) {
                                _topics.obtain(entityName, null, function(error) {
                                    statusChecker(error, resolve, reject);
                                }.bindenv(this));
                            }
                            else {
                                _subscrs.obtain(entityName, null, function(error, subscrConfig) {
                                    statusChecker(error, resolve, reject);
                                }.bindenv(this));
                            }
                        }.bindenv(this))
                    }.bindenv(this));
            }.bindenv(this));
    }

    function _pubSubDelay() {
        return Promise(function (resolve, reject) {
            imp.wakeup(GOOGLE_PUB_SUB_DELAY_SEC, function() {
                return resolve("");
            }.bindenv(this));
        }.bindenv(this));
    }
}
