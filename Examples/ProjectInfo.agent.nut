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

// OAuth 2.0 library required for GooglePubSub
#require "OAuth2.agent.lib.nut:1.0.0"

#require "GooglePubSub.agent.lib.nut:1.1.0"

#require "PrettyPrinter.class.nut:1.0.1"

// Collects and prints information about the Google Cloud Project:
// list of topics, topics IAM Policy, list of subscriptions related to every topic,
// subscriptions configuration and IAM Policy.
class ProjectInfoCollector {
    _projectInfo = null;
    _requests = 0;
    _topics = null;
    _subscrs = null;

    constructor(projectId, oAuthTokenProvider) {
        _projectInfo = {};
        _topics = GooglePubSub.Topics(projectId, oAuthTokenProvider);
        _subscrs = GooglePubSub.Subscriptions(projectId, oAuthTokenProvider);
    }

    // Collects IAM policy info for topics and subscriptions
    function collectPolicyInfo(error, policy, resourceInfo) {
        local policyInfo;
        if (error) {
            policyInfo = "Get Policy request failed: " + error.details;
        }
        else {
            policyInfo = {
                "version" : policy.version,
                "bindings" : policy.bindings,
                "etag" : policy.etag
            };
        }
        resourceInfo["IAM Policy"] <- policyInfo;
    }

    // Collects subscription info: IAM Policy and subscription configuration
    function collectSubscriptionInfo(subscrName, info) {
        local subscrInfo = {};
        info[subscrName] <- subscrInfo;

        // obtain the subscription IAM policy
        _requests++;
        _subscrs.iam().getPolicy(subscrName, function(error, policy) {
            collectPolicyInfo(error, policy, subscrInfo);
            _requests--;
        }.bindenv(this));

        // obtain the subscription configuration
        _requests++;
        _subscrs.obtain(subscrName, null, function(error, subscrConfig) {
            if (error) {
                subscrInfo["Config"] <- "Subscription obtain request failed: " + error.details;
            }
            else {
                local config = {
                    "ackDeadlineSeconds" : subscrConfig.ackDeadlineSeconds,
                };
                local pushConfig = subscrConfig.pushConfig;
                if (pushConfig && pushConfig.pushEndpoint) {
                    config["pushConfig"] <- {
                        "pushEndpoint" : pushConfig.pushEndpoint,
                        "attributes" : pushConfig.attributes
                    };
                }
                subscrInfo["Config"] <- config;
            }
            _requests--;
        }.bindenv(this));
    }

    // Collects topic info: IAM Policy and list of subscriptions
    function collectTopicInfo(topicName, info) {
        local topicInfo = {};
        info[topicName] <- topicInfo;

        // obtain the topic IAM policy
        _requests++;
        _topics.iam().getPolicy(topicName, function(error, policy) {
            collectPolicyInfo(error, policy, topicInfo);
            _requests--;
        }.bindenv(this));

        // obtain the topic subscriptions
        _requests++;
        _subscrs.list({ "topicName" : topicName }, function(error, subscrNames, nextOptions) {
            local subscrs;
            if (error) {
                subscrs = "Subscriptions list request failed: " + error.details;
            }
            else {
                subscrs = [];
                // subscrNames contains names of all subscriptions related to the topic
                foreach (subscrName in subscrNames) {
                    local subscrInfo = {};
                    collectSubscriptionInfo(subscrName, subscrInfo);
                    subscrs.push(subscrInfo);
                }
            }
            topicInfo["Subscriptions"] <- subscrs;
            _requests--;
        }.bindenv(this));
    }

    // Collects project info
    function collectProjectInfo(projectInfo) {
        _requests++;
        _topics.list({ "paginate" : false }, function(error, topicNames, nextOptions) {
            local topics;
            if (error) {
                topics = "Topics list request failed: " + error.details;
            }
            else {
                topics = [];
                // topicNames contains names of all topics registered to the project
                foreach (topicName in topicNames) {
                    local topicInfo = {};
                    topics.push(topicInfo);
                    collectTopicInfo(topicName, topicInfo);
                }
            }
            projectInfo["Topics"] <- topics;
            _requests--;
        }.bindenv(this));
    }

    // Prints project info
    function printInfo() {
        imp.wakeup(1.0, function() {
            if (_requests > 0) {
                printInfo();
            }
            else {
                server.log("Project info:");
                PrettyPrinter(null, false).print(_projectInfo);
            }
        }.bindenv(this));
    }

    // Collects and prints project info
    function printProjectInfo() {
        collectProjectInfo(_projectInfo);
        printInfo();
    }
}

// Configuration constants, substitute with real values
const PROJECT_ID = "...";
const GOOGLE_ISS = "...";
const GOOGLE_SECRET_KEY = "...";

// obtaining OAuth2 Access Tokens Provider
local oAuthTokenProvider = OAuth2.JWTProfile.Client(
    OAuth2.DeviceFlow.GOOGLE,
    {
        "iss"         : GOOGLE_ISS,
        "jwtSignKey"  : GOOGLE_SECRET_KEY,
        "scope"       : "https://www.googleapis.com/auth/pubsub"
    });

// Start Application
projectInfoCollector <- ProjectInfoCollector(PROJECT_ID, oAuthTokenProvider);
projectInfoCollector.printProjectInfo();
