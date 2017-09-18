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

// GooglePubSub library provides an integration with Google Cloud Pub/Sub service using
// Google Cloud Pub/Sub REST API.
//
// Google Cloud Pub/Sub is a publish/subscribe (Pub/Sub) service:
// a messaging service where the senders of messages are decoupled from the receivers
// of messages. There are several key concepts in a Pub/Sub service:
//   - Message: the data that moves through the service.
//   - Topic: a named resource that represents a feed of messages.
//   - Subscription: a named resource that represents an interest in receiving messages
//     on a particular topic.
//   - Publisher: creates messages and sends (publishes) them to the messaging service
//     on a specified topic.
//   - Subscriber: receives messages on a specified subscription.
// Communication between publishers and subscribers can be one-to-many, many-to-one,
// and many-to-many.
//
// Pub/Sub Message flow steps:
// 1. A publisher application creates a topic in the Google Cloud Pub/Sub service and
//    sends messages to the topic. A message contains a payload and optional attributes
//    that describe the payload content.
// 2. Messages are persisted in a Google Pub/Sub message store until they are delivered
//    and acknowledged by subscribers.
// 3. The Pub/Sub service forwards messages from a topic to all of its subscriptions,
//    individually.
//    Each subscription receives messages either by Pub/Sub pushing them to the subscriber's
//    chosen endpoint, or by the subscriber pulling them from the service.
// 4. The subscriber receives pending messages from its subscription and acknowledges each
//    one to the Pub/Sub service.
// 5. When a message is acknowledged by the subscriber, it is removed from the subscription's
//    queue of messages.
//
// For more information see Google Cloud Pub/Sub Documentation
// https://cloud.google.com/pubsub/docs/overview
//
// Before using this library you need to:
//   - register Google Cloud Platform account
//   - create and configure Google Cloud Project
//
// Google Cloud Project is a basic entity of Google Cloud Platform which allows to create,
// configure and use all Cloud Platform resources and services, including Pub/Sub.
// All Pub/Sub Topics and Subscriptions are owned by a specific Project.
// To manage Pub/Sub resources associated with different Projects, you may use
// different instances of the classes from this library.
//
// For more information about Google Cloud Project see
// https://cloud.google.com/resource-manager/docs/creating-managing-projects
//
// The library consists of five independent parts (classes):
//
//   - GooglePubSub.Topics - provides access to Pub/Sub Topics manipulation methods.
//     One instance of this class is enough to manage all topics of one Project.
//
//   - GooglePubSub.Subscriptions - provides access to Pub/Sub Subscriptions manipulation methods.
//     One instance of this class is enough to manage all subscriptions of one Project.
//
//   - GooglePubSub.Publisher - allows to publish messages to a topic.
//     One instance of this class allows to publish messages to one topic.
//
//   - GooglePubSub.PullSubscriber - allows to receive messages from a pull subscription.
//     One instance of this class allows to receive messages from one pull subscription.
//
//   - GooglePubSub.PushSubscriber - allows to receive messages from a push subscription
//     configured with imp Agent related URL as push endpoint.
//     One instance of this class allows to receive messages from one push subscription.
//
// You can instantiate and use any parts of the library in your imp agent code depending on your
// application requirements.
//
// To instantiate every part (class) of this library you need to have:
//
//   - Google Cloud Platform Project ID
//
//   - Provider of access tokens suitable for Google Pub/Sub service requests authentication.
//     For more information about Google Pub/Sub service authentication see
//     https://cloud.google.com/docs/authentication
//
//     The library requires acquireAccessToken(tokenReadyCallback) method of the provider, where
//     tokenReadyCallback is a handler to be called when access token is acquired or an error occurs.
//     It has the following signature:
//     tokenReadyCallback(token, error), where
//         token : string    String representation of access token.
//         error : string    String with error details, null in case of success.
//
//     Token provider can be an instance of OAuth2.JWTProfile.Client OAuth2 library
//     (see https://github.com/electricimp/OAuth-2.0)
//     or any other access token provider with a similar interface.
//
// Also, the library includes several additional auxiliary classes.
//
// All requests to Google Cloud Pub/Sub service are made asynchronously.
// Any method that sends a request has an optional callback parameter.
// If the callback is provided, it is executed when the operation is completed
// (e.g. a response is received), successfully or not.
// Details of every callback are described in the corresponding methods.

// GooglePubSub library operation error types
enum PUB_SUB_ERROR {
    // the library detects an error, e.g. the library is wrongly initialized or
    // a method is called with invalid argument(s). The error details can be
    // found in the error.details value
    LIBRARY_ERROR,
    // HTTP request to Google Pub/Sub service failed. The error details can be found in
    // the error.httpStatus and error.httpResponse properties
    PUB_SUB_REQUEST_FAILED,
    // Unexpected response from Google Pub/Sub service. The error details can be found in
    // the error.details and error.httpResponse properties
    PUB_SUB_UNEXPECTED_RESPONSE
};

// Error details produced by the library
const GOOGLE_PUB_SUB_TOKEN_ACQUISITION_ERROR = "Access token acquisition error";
const GOOGLE_PUB_SUB_REQUEST_FAILED = "Google Pub/Sub request failed with status code";
const GOOGLE_PUB_SUB_NON_EMPTY_ARG = "Non empty argument required";
const GOOGLE_PUB_SUB_POSITIVE_ARG = "Positive argument required";
const GOOGLE_PUB_SUB_WRONG_ARG_TYPE = "Invalid type of argument, required";
const GOOGLE_PUB_SUB_PULL_IN_PROGRESS = "Different pull is active";
const GOOGLE_PUB_SUB_PUSH_SUBSCR_REQUIRED = "Push subscription required";
const GOOGLE_PUB_SUB_INTERNAL_PUSH_REQUIRED = "Push endpoint based on imp Agent URL required";
const GOOGLE_PUB_SUB_OPTION_REQUIRED = "option must be specified";
const GOOGLE_PUB_SUB_INVALID_FORMAT = "Invalid format of";

class GooglePubSub {
    static VERSION = "1.0.0";

    // Enables/disables the library debug output (including errors logging).
    // Disabled by default.
    //
    // Parameters:
    //     value : boolean           true to enable, false to disable
    function setDebug(value) {
        _utils._debug = value;
    }

    // Internal utility methods used by different parts of the library
    static _utils = {
        _debug = false,

        // Logs an error occurred during the library methods execution
        function _logError(errMessage) {
            if (_debug) {
                server.error("[GooglePubSub] " + errMessage);
            }
        }

        // Logs an debug messages occurred during the library methods execution
        function _logDebug(message) {
            if (_debug) {
                server.log("[GooglePubSub] " + message);
            }
        }

        // Converts a value to an array
        function _arrify(value) {
            if (typeof value == "array") {
                return value;
            }
            else if (value == null) {
                return [];
            }
            else {
                return array(1, value);
            }
        }

        // Returns value of specified table key, if exists or defaultValue
        function _getTableValue(table, key, defaultValue) {
            return (table && key in table) ? table[key] : defaultValue;
        }

        // Checks if value is empty (null, empty string, empty table or empty array)
        function _isEmpty(value) {
            if (value == null || typeof value == "string" && value.len() == 0 ||
                typeof value == "table" && value.len() == 0 ||
                typeof value == "array" && value.len() == 0) {
                return true;
            }
            return false;
        }

        // Validates the argument is not empty. Returns PUB_SUB_ERROR.LIBRARY_ERROR if the check failed.
        function _validateNonEmptyArg(param, paramName, logError = true) {
            if (_isEmpty(param)) {
                return GooglePubSub.Error(
                    PUB_SUB_ERROR.LIBRARY_ERROR,
                    format("%s: %s", GOOGLE_PUB_SUB_NON_EMPTY_ARG, paramName),
                    null, null, logError);
            }
            return null;
        }

        // Validates the argument is positive and belongs to the specified type.
        // Returns PUB_SUB_ERROR.LIBRARY_ERROR if the check failed.
        function _validatePositiveArg(param, paramName, type = "integer") {
            if (type && typeof param != type) {
                return GooglePubSub.Error(
                    PUB_SUB_ERROR.LIBRARY_ERROR,
                    format("%s %s: %s", GOOGLE_PUB_SUB_WRONG_ARG_TYPE, type, paramName));
            }
            if (param <= 0) {
                return GooglePubSub.Error(
                    PUB_SUB_ERROR.LIBRARY_ERROR,
                    format("%s: %s", GOOGLE_PUB_SUB_POSITIVE_ARG, paramName));
            }
            return null;
        }

        // Invokes default callback with single error parameter.
        function _invokeDefaultCallback(error, callback) {
            if (callback) {
                imp.wakeup(0, function () {
                    callback(error);
                });
            }
        }
    };
}

// Auxiliary class, represents error returned by the library.
class GooglePubSub.Error {
    // error type, one of the PUB_SUB_ERROR enum values
    type = null;

    // error details (string)
    details = null;

    // HTTP status code (integer),
    // null if type is PUB_SUB_ERROR.LIBRARY_ERROR
    httpStatus = null;

    // Response body of failed request (table),
    // null if type is PUB_SUB_ERROR.LIBRARY_ERROR
    httpResponse = null;

    constructor(type, details, httpResponse = null, httpStatus = null, logError = true) {
        this.type = type;
        this.details = details;
        this.httpStatus = httpStatus;
        this.httpResponse = httpResponse;
        if (logError) {
            GooglePubSub._utils._logError(details);
        }
    }
}

// Internal GooglePubSub library constants
const _GOOGLE_PUB_SUB_BASE_URL = "https://pubsub.googleapis.com/v1";
const _GOOGLE_PUB_SUB_TOPICS_TYPE = "topics";
const _GOOGLE_PUB_SUB_SUBSCRIPTIONS_TYPE = "subscriptions";
const _GOOGLE_PUB_SUB_LIST_PAGE_SIZE_DEFAULT = 20;
const _GOOGLE_PUB_SUB_PULL_MAX_MESSAGES_DEFAULT = 20;
const _GOOGLE_PUB_SUB_ACK_DEADLINE_SECONDS_DEFAULT = 10;

// This class provides access to Pub/Sub Topics manipulation methods.
// It can be used to check existence, create, delete topics of the specified Project
// and obtain a list of the topics registered to the Project.
class GooglePubSub.Topics {
    _projectId = null;
    _oAuthTokenProvider = null;
    _topic = null;
    _iam = null;

    // GooglePubSub.Topics constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //
    // Returns:                      GooglePubSub.Topics instance created
    constructor(projectId, oAuthTokenProvider) {
        _projectId = projectId;
        _oAuthTokenProvider = oAuthTokenProvider;
        _topic = GooglePubSub._Resource(projectId, oAuthTokenProvider, _GOOGLE_PUB_SUB_TOPICS_TYPE);
        _iam = GooglePubSub.IAM(_topic);
    }

    // Checks if the specified topic exists and optionally creates it if not.
    // If the topic does not exist and autoCreate option is true, the topic is created.
    // If the topic does not exist and autoCreate option is false, the method fails with
    // PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED error (with httpStatus 404).
    //
    // Parameters:
    //     topicName : string        Name of the topic.
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                   autoCreate : boolean     Create the topic if it
    //                                                            does not exist.
    //                                                            Default: false
    //     callback : function       Optional callback function to be executed once the topic is
    //         (optional)            checked or created.
    //                               The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function obtain(topicName, options = null, callback = null) {
        _topic.setName(topicName);
        _topic.obtain(
            options,
            null,
            function (error, httpResponse) {
                GooglePubSub._utils._invokeDefaultCallback(error, callback);
            }.bindenv(this));
    }

    // Deletes the specified topic, if it exists.
    // Otherwise - fails with PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED error (with httpStatus 404).
    //
    // Existing subscriptions to the deleted topic are not destroyed.
    //
    // After the topic is deleted, a new topic may be created with the same name;
    // this is an entirely new topic with none of the old configuration or subscriptions.
    //
    // Parameters:
    //     topicName : string        Name of the topic.
    //     callback : function       Optional callback function to be executed once the topic is deleted.
    //         (optional)            The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function remove(topicName, callback = null) {
        _topic.setName(topicName);
        _topic.remove(function (error, httpResponse) {
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
        }.bindenv(this));
    }

    // Gets a list of the topics (names of all topics) registered to the project.
    //
    // Parameters:
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                   paginate : boolean       If true, the method returns limited
    //                                                            number of topics (up to pageSize)
    //                                                            and pageToken which allows to obtain next
    //                                                            page of data.
    //                                                            If false, the method returns the entire
    //                                                            list of topics.
    //                                                            Default: false
    //                                   pageSize : integer       Maximum number of topics to return.
    //                                                            If paginate option value is false,
    //                                                            the value is ignored.
    //                                                            Default: 20
    //                                   pageToken : string       Page token returned by the previous
    //                                                            paginated GooglePubSub.Topics.list() call;
    //                                                            indicates that the system should return
    //                                                            the next page of data.
    //                                                            If paginate option value is false,
    //                                                            the value is ignored.
    //     callback : function       Optional callback function to be executed once the topics are obtained.
    //         (optional)            The callback signature:
    //                               callback(error, topicNames, nextOptions = null), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //                                   topicNames :             Names of topics obtained.
    //                                     array of string
    //                                   nextOptions : table      Options table that can be used for subsequent
    //                                                            paginated GooglePubSub.Topics.list() call.
    //                                                            Contains pageToken returned by the current
    //                                                            GooglePubSub.Topics.list() call.
    //                                                            Has null value if:
    //                                                              - no more results are available,
    //                                                              - paginate option value is false,
    //                                                              - the current list() operation failed.
    //
    // Returns:                      Nothing
    function list(options = null, callback = null) {
        _topic.list(options, callback);
    }

    // Provides Identity and Access Management (IAM) functionality for topics.
    // (see GooglePubSub.IAM class description for details)
    //
    // Returns:                      An instance of IAM class that can be used for execution of
    //                               IAM methods for a specific topic.
    function iam() {
        return _iam;
    }
}

// This class provides access to Pub/Sub Subscriptions manipulation methods.
// It can be used to check existence, create, configure, delete subscriptions of the specified Project
// and obtain a list of the subscriptions registered to the Project or related to a topic.
//
// Information about Google Pub/Sub subscriptions see here:
// https://cloud.google.com/pubsub/docs/subscriber
//
// A subscription configuration is encapsulated in GooglePubSub.SubscriptionConfig class.
// The library allows to manipulate with the both - pull and push - types of subscription.
// Additional configuration parameters for a push subscription are encapsulated in
// GooglePubSub.PushConfig class.
//
// The library provides GooglePubSub.PullSubscriber class to receive messages from a pull subscription.
//
// A push subscription configuration has a pushEndpoint parameter -
// URL to a custom endpoint that messages should be pushed to.
// In a general case it may be any URL and receiving of the push subscription messages
// is out of the library's scope.
// But it is possible to specify a push endpoint URL which is based on imp Agent URL.
// Auxiliary GooglePubSub.Subscriptions.getImpAgentEndpoint() method may be used to generate such an URL.
// In this case GooglePubSub.PushSubscriber class can be utilized to receive messages from the push subscription.
//
class GooglePubSub.Subscriptions {
    _projectId = null;
    _oAuthTokenProvider = null;
    _subscr = null;
    _iam = null;

    // GooglePubSub.Subscriptions constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //
    // Returns:                      GooglePubSub.Subscriptions instance created
    constructor(projectId, oAuthTokenProvider) {
        _projectId = projectId;
        _oAuthTokenProvider = oAuthTokenProvider;
        _subscr = GooglePubSub._Resource(projectId, oAuthTokenProvider, _GOOGLE_PUB_SUB_SUBSCRIPTIONS_TYPE);
        _iam = GooglePubSub.IAM(_subscr);
    }

    // Obtains (get or create) the specified subscription.
    // If subscription with the specified name exists, the method retrieves it's configuration.
    // If it does not exist and optional autoCreate option is true, the subscription is created.
    // In this case subscrConfig option must be specified.
    // If the subscription does not exist and autoCreate option is false, the method fails with
    // PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED error (with httpStatus 404).
    //
    // Parameters:
    //     subscrName : string       Name of the subscription.
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                 autoCreate : boolean               Create the subscription
    //                                                                    if it does not exist.
    //                                                                    Default: false
    //                                 subscrConfig :                     Configuration of subscription
    //                                   GooglePubSub.SubscriptionConfig  to be created.
    //                                     (optional)                     subscrConfig must be specified
    //                                                                    if autoCreate option is true,
    //                                                                    otherwise it is ignored.
    //     callback : function       Optional callback function to be executed once the subscription is obtained.
    //         (optional)            The callback signature:
    //                               callback(error, subscrConfig), where
    //                                 error :                            Error details,
    //                                   GooglePubSub.Error               null if the operation succeeds.
    //                                 subscrConfig :                     Configuration of the subscription
    //                                   GooglePubSub.SubscriptionConfig  obtained.
    //
    // Returns:                      Nothing
    function obtain(subscrName, options = null, callback = null) {
        local autoCreate = GooglePubSub._utils._getTableValue(options, "autoCreate", false);
        local subscrConfig = GooglePubSub._utils._getTableValue(options, "subscrConfig", null);
        if (autoCreate && !subscrConfig) {
            _invokeObtainCallback(
                GooglePubSub.Error(PUB_SUB_ERROR.LIBRARY_ERROR, format("%s %s", "subscrConfig", GOOGLE_PUB_SUB_OPTION_REQUIRED)),
                null, callback);
            return;
        }
        if (subscrConfig) {
            local configError = subscrConfig._getError();
            if (configError) {
                _invokeObtainCallback(configError, null, callback);
                return;
            }
        }
        _subscr.setName(subscrName);
        _subscr.obtain(
            options,
            subscrConfig ? subscrConfig._toJson(_projectId) : null,
            function (error, httpResponse) {
                local subscrCfg = null;
                if (!error) {
                    subscrCfg = GooglePubSub.SubscriptionConfig(null);
                    subscrCfg._fromJson(httpResponse, _projectId);
                }
                _invokeObtainCallback(error, subscrCfg, callback);
            }.bindenv(this));
    }

    // Modifies push delivery endpoint configuration for the specified subscription.
    // The method may be used to change a push subscription to a pull one or vice versa,
    // or change the endpoint URL and other attributes of a push subscription.
    //
    // To modify a push subscription to a pull one, pass null or empty table as a pushConfig parameter
    // value.
    //
    // Parameters:
    //     subscrName : string       Name of the subscription.
    //     pushConfig :              The push configuration for future deliveries.
    //       GooglePubSub.PushConfig An empty pushConfig indicates that the Pub/Sub service should stop
    //                               pushing messages from the given subscription and allow messages
    //                               to be pulled and acknowledged.
    //     callback : function       Optional callback function to be executed once the Push Config is modified.
    //         (optional)            The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function modifyPushConfig(subscrName, pushConfig, callback = null) {
        _subscr.setName(subscrName);
        if (pushConfig) {
            local configError = pushConfig._getError();
            if (configError) {
                GooglePubSub._utils._invokeDefaultCallback(configError, callback);
                return;
            }
        }
        _subscr.request(
            "POST",
            ":modifyPushConfig",
            pushConfig ? { "pushConfig" : pushConfig._toJson() } : {},
            function (error, httpResponse) {
                GooglePubSub._utils._invokeDefaultCallback(error, callback);
            }.bindenv(this));
    }

    // Deletes the specified subscription, if it exists.
    // Otherwise - fails with PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED error (with httpStatus 404).
    //
    // All messages retained in the subscription are immediately dropped
    // and cannot be delivered neither by pull, nor by push ways.
    //
    // After the subscription is deleted, a new one may be created with the same name, but the new one has no
    // association with the old subscription or its topic unless the same topic is specified.
    //
    // Parameters:
    //     subscrName : string       Name of the subscription.
    //     callback : function       Optional callback function to be executed once the subscription is deleted.
    //         (optional)            The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function remove(subscrName, callback = null) {
        _subscr.setName(subscrName);
        _subscr.remove(function (error, httpResponse) {
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
        }.bindenv(this));
    }

    // Gets a list of the subscriptions (names of all subscriptions) registered to the project
    // or related to the specified topic.
    //
    // Parameters:
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                   topicName : string       Name of the topic to list subscriptions from.
    //                                   paginate : boolean       If true, the method returns limited
    //                                                            number of subscriptions (up to pageSize)
    //                                                            and pageToken which allows to obtain next
    //                                                            page of data.
    //                                                            If false, the method returns the entire
    //                                                            list of subscriptions.
    //                                                            Default: false
    //                                   pageSize : integer       Maximum number of subscriptions to return.
    //                                                            If paginate option value is false,
    //                                                            the value is ignored.
    //                                                            Default: 20
    //                                   pageToken : string       Page token returned by the previous paginated
    //                                                            GooglePubSub.Subscriptions.list() call;
    //                                                            indicates that the system should return
    //                                                            the next page of data.
    //                                                            If paginate option value is false,
    //                                                            the value is ignored.
    //     callback : function       Optional callback function to be executed once the subscriptions are obtained.
    //         (optional)            The callback signature:
    //                               callback(error, subscrNames, nextOptions = null), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //                                   subscrNames :            Names of subscriptions obtained.
    //                                     array of string
    //                                   nextOptions : table      Options table that can be used for subsequent
    //                                                            paginated GooglePubSub.Subscriptions.list() call.
    //                                                            Contains pageToken returned by the current
    //                                                            GooglePubSub.Subscriptions.list() call.
    //                                                            Has null value if:
    //                                                              - no more results are available,
    //                                                              - paginate option value is false,
    //                                                              - the current list() operation failed.
    //
    // Returns:                      Nothing
    function list(options = null, callback = null) {
        local topicName = GooglePubSub._utils._getTableValue(options, "topicName", null);
        if (topicName) {
            local topic = GooglePubSub._Resource(_projectId, _oAuthTokenProvider, _GOOGLE_PUB_SUB_TOPICS_TYPE);
            topic.setName(topicName);
            _subscr._list(topic.getResourceUrl(), options, true, callback);
        }
        else {
            _subscr.list(options, callback);
        }
    }

    // Provides Identity and Access Management (IAM) functionality for subscriptions.
    // (see GooglePubSub.IAM class description for details)
    //
    // Returns:                      An instance of IAM class that can be used for execution of
    //                               IAM methods for a specific subscription.
    function iam() {
        return _iam;
    }

    // Auxiliary method to compose a endpoint URL based on imp Agent URL.
    // The result URL can be used to create a push subscription and receive
    // messages from this subscription using GooglePubSub.PushSubscriber class.
    //
    // Parameters:
    //     relativePath :            Optional relative path from imp Agent URL.
    //         string                If specified, <imp Agent URL>/<relativePath>
    //         (optional)            is returned.
    //                               If not specified or empty, <imp Agent URL> is
    //                               returned.
    //     secretToken :             Optional secret token specified by a user.
    //         string                It allows to verify that the messages
    //         (optional)            pushed to the push endpoint are originated
    //                               from Google Cloud Pub/Sub.
    //                               For more information see
    //                               https://cloud.google.com/pubsub/docs/faq#security
    //
    // Returns:                      URL based on imp Agent URL
    function getImpAgentEndpoint(relativePath = null, secretToken = null) {
        local endpoint = http.agenturl();
        if (relativePath) {
            endpoint = format("%s/%s", endpoint, relativePath);
        }
        if (endpoint.slice(endpoint.len() - 1) != "/") {
            endpoint = endpoint + "/";
        }
        if (secretToken) {
            endpoint = format("%s?token=%s", endpoint, secretToken);
        }
        return endpoint;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _invokeObtainCallback(error, subscrConfig, callback) {
        if (callback) {
            imp.wakeup(0, function () {
                callback(error, subscrConfig);
            });
        }
    }
}

// Auxiliary class, represents configuration of a subscription.
class GooglePubSub.SubscriptionConfig {
    // Name of the topic from which this subscription receives messages.
    topicName = null;

    // The maximum time (in seconds) after receiving a message when the message must be acknowledged
    // before it is redelivered by Pub/Sub service.
    ackDeadlineSeconds = null;

    // Push subscription configuration (GooglePubSub.PushConfig). Null for pull subscriptions.
    pushConfig = null;

    // SubscriptionConfig constructor that can be used for creating subscription using
    // GooglePubSub.Subscriptions.obtain() method.
    //
    // Parameters:
    //     topicName : string           Name of the topic associated with the subscription.
    //     ackDeadlineSeconds :         The maximum time (in seconds) after receiving
    //         integer                  a message when the message must be acknowledged
    //         (optional)               before it is redelivered by Pub/Sub service.
    //                                  Default : 10
    //     pushConfig :                 Configuration for a push delivery endpoint.
    //         GooglePubSub.PushConfig  Null for pull subscriptions.
    //         (optional)
    //
    // Returns:                         GooglePubSub.SubscriptionConfig instance created.
    constructor(topicName, ackDeadlineSeconds = _GOOGLE_PUB_SUB_ACK_DEADLINE_SECONDS_DEFAULT, pushConfig = null) {
        this.topicName = topicName;
        this.ackDeadlineSeconds = ackDeadlineSeconds;
        this.pushConfig = pushConfig;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _toJson(projectId) {
        local topic = GooglePubSub._Resource(projectId, null, _GOOGLE_PUB_SUB_TOPICS_TYPE);
        topic.setName(topicName);
        local result = {
            "topic" : topic.getResourceName(),
            "ackDeadlineSeconds" : ackDeadlineSeconds
        };
        if (pushConfig) {
            result["pushConfig"] <- pushConfig._toJson();
        }
        return result;
    }

    function _fromJson(jsonSubscrConfig, projectId) {
        topicName = null;
        ackDeadlineSeconds = null;
        pushConfig = null;
        local topic = GooglePubSub._utils._getTableValue(jsonSubscrConfig, "topic", null);
        if (topic) {
            topicName = GooglePubSub._Resource(projectId, null, _GOOGLE_PUB_SUB_TOPICS_TYPE).getName(topic);
        }
        ackDeadlineSeconds = GooglePubSub._utils._getTableValue(
            jsonSubscrConfig, "ackDeadlineSeconds", _GOOGLE_PUB_SUB_ACK_DEADLINE_SECONDS_DEFAULT);

        local pushCfg = GooglePubSub._utils._getTableValue(jsonSubscrConfig, "pushConfig", null);
        if (!GooglePubSub._utils._isEmpty(pushCfg)) {
            pushConfig = GooglePubSub.PushConfig(null);
            pushConfig._fromJson(pushCfg);
        }
    }

    function _getError() {
        return GooglePubSub._utils._validateNonEmptyArg(topicName, "topicName") ||
            GooglePubSub._utils._validatePositiveArg(ackDeadlineSeconds, "ackDeadlineSeconds") ||
            (pushConfig ? pushConfig._getError() : null);
    }
}

// Auxiliary class, represents additional configuration of a push subscription.
class GooglePubSub.PushConfig {
    // A URL to a custom endpoint that messages should be pushed to.
    pushEndpoint = null;

    // Push endpoint attributes: key-value table of string attributes.
    // For more information about Push Config valid attributes, see
    // https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.subscriptions#PushConfig
    attributes = null;

    // PushConfig constructor that can be used for creating push subscription.
    //
    // Parameters:
    //     pushEndpoint : string     Push endpoint URL.
    //     attributes : table        Optional push endpoint attributes.
    //         (optional)
    //
    // Returns:                      GooglePubSub.PushConfig instance created.
    constructor(pushEndpoint, attributes = null) {
        this.pushEndpoint = pushEndpoint;
        this.attributes = attributes;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _toJson() {
        local result = {
            "pushEndpoint" : pushEndpoint
        };
        if (attributes) {
            result["attributes"] <- attributes;
        }
        return result;
    }

    function _fromJson(jsonPushConfig) {
        pushEndpoint = GooglePubSub._utils._getTableValue(jsonPushConfig, "pushEndpoint", null);
        attributes = GooglePubSub._utils._getTableValue(jsonPushConfig, "attributes", null);
    }

    function _getError() {
        return GooglePubSub._utils._validateNonEmptyArg(pushEndpoint, "pushEndpoint");
    }
}

// Auxiliary class, provides Identity and Access Management (IAM) functionality for individual Pub/Sub
// resources (topics and subscriptions).
// IAM allows you to manage access control by defining who (members) has what access (role) for which
// resource.
// For example:
// - Grant access to any operation with particular topic or subscription to a specific user or group of users.
// - Grant access with limited capabilities, such as to only publish messages to a topic, or to only
//   consume messages from a subscription, but not to delete the topic or subscription.
//
// It is assumed that this class is not instantiated by a user directly,
// but GooglePubSub.Topics.iam() and GooglePubSub.Subscriptions.iam() functions are used to get the instances
// and execute IAM methods for topics and subscriptions respectively.
//
// IAM policy representation is encapsulated in GooglePubSub.IAM.Policy class.
//
// For a detailed description of IAM and its features, see the Google Cloud Identity and Access
// Management Documentation: https://cloud.google.com/iam/docs/overview
//
class GooglePubSub.IAM {
    _resource = null;

    constructor(resource) {
        _resource = resource;
    }

    // Gets the access control policy for a resource.
    // Returns an empty policy if the resource exists and does not have a policy set.
    //
    // Parameters:
    //     resourceName : string     Name of the topic or subscription.
    //     callback : function       Optional callback function to be executed once the policy is obtained.
    //         (optional)            The callback signature:
    //                               callback(error, policy), where
    //                                 error :                    Error details,
    //                                   GooglePubSub.Error       null if the operation succeeds.
    //                                 policy :                   IAM policy obtained for the resource.
    //                                   GooglePubSub.IAM.Policy
    //
    // Returns:                      Nothing
    function getPolicy(resourceName, callback = null) {
        _resource.setName(resourceName);
        _resource.getIamPolicy(function (error, httpResponse) {
            _invokePolicyCallback(error, httpResponse, callback);
        }.bindenv(this));
    }

    // Sets the access control policy on the specified resource. Replaces any existing policy.
    //
    // Parameters:
    //     resourceName : string     Name of the topic or subscription.
    //     policy :                  The policy to be set.
    //       GooglePubSub.IAM.Policy
    //     callback : function       Optional callback function to be executed once the policy is set.
    //         (optional)            The callback signature:
    //                               callback(error, policy), where
    //                                 error :                    Error details,
    //                                   GooglePubSub.Error       null if the operation succeeds.
    //                                 policy :                   IAM policy was set.
    //                                   GooglePubSub.IAM.Policy
    //
    // Returns:                      Nothing
    function setPolicy(resourceName, policy, callback = null) {
        local policyError = GooglePubSub._utils._validateNonEmptyArg(policy, "policy");
        if (policyError) {
            _invokePolicyCallback(policyError, null, callback);
            return;
        }
        _resource.setName(resourceName);
        _resource.setIamPolicy(policy, function (error, httpResponse) {
            _invokePolicyCallback(error, httpResponse, callback);
        }.bindenv(this));
    }

    // Tests a set of permissions for a resource.
    // If the resource does not exist, this method will return an empty set of permissions,
    // not a PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED error.
    //
    // Permissions with wildcards such as * or pubsub.topics.* are not allowed.
    //
    // For a list of the permissions available, see Google Cloud Pub/Sub Access Control documentation:
    // https://cloud.google.com/pubsub/docs/access_control
    //
    // Parameters:
    //     resourceName : string     Name of the topic or subscription.
    //     permissions : string or   The permission(s) to test for a resource.
    //         array of strings
    //     callback : function       Optional callback function to be executed once the permissions are tested.
    //         (optional)            The callback signature:
    //                               callback(error, permissions), where
    //                                 error :                    Error details,
    //                                   GooglePubSub.Error       null if the operation succeeds.
    //                                 permissions :              A subset of permissions that is allowed
    //                                   array of strings         for the resource.
    //
    // Returns:                      Nothing
    function testPermissions(resourceName, permissions, callback = null) {
        local error = GooglePubSub._utils._validateNonEmptyArg(permissions, "permissions");
        if (error) {
            imp.wakeup(0, function () {
                callback(error, null);
            });
            return;
        }
        _resource.setName(resourceName);
        _resource.testIamPermissions(permissions, function (error, httpResponse) {
            if (callback) {
                local permissions = null;
                if (!error) {
                    permissions = GooglePubSub._utils._getTableValue(httpResponse, "permissions", []);
                }
                imp.wakeup(0, function () {
                    callback(error, permissions);
                });
            }
        }.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _invokePolicyCallback(error, httpResponse, callback) {
        if (callback) {
            local policy = null;
            if (!error) {
                policy = GooglePubSub.IAM.Policy(null);
                policy._fromJson(httpResponse);
            }
            imp.wakeup(0, function () {
                callback(error, policy);
            });
        }
    }
}

// Auxiliary class, represents Identity and Access Management (IAM) policy.
// For more information about IAM Policy see https://cloud.google.com/iam/docs/overview
// and https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy
class GooglePubSub.IAM.Policy {
    // Version of the Policy (integer)
    version = null;

    // Array of bindings (tables { "role" : string, "members" : array of strings })
    // Every binding binds a list of members to a role, where the members can be
    // user accounts, Google groups, Google domains, service accounts.
    // A role is a named set of permissions defined by IAM.
    // For a list of roles Google Cloud Pub/Sub IAM supports, see Google Cloud Pub/Sub
    // Access Control documentation: https://cloud.google.com/pubsub/docs/access_control
    bindings = null;

    // Entity tag
    // For more information see https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy
    etag = null;

    // GooglePubSub.IAM.Policy constructor that can be used to set resource policy
    // using GooglePubSub.IAM.setPolicy() method.
    //
    // Parameters:
    //     version : integer         Version of the Policy.
    //         (optional)            Default : 0
    //     bindings : array          Array of bindings: associations between a role and
    //       of tables               a list of members.
    //       { "role" : string,      For more information see https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy
    //         "members" : array     and https://cloud.google.com/pubsub/docs/access_control
    //                  of strings }
    //     etag : string             Entity tag
    //         (optional)            For more information see https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy
    // Returns:                      GooglePubSub.IAM.Policy instance created.
    constructor(version = 0, bindings = null, etag = null) {
        this.version = version;
        this.bindings = bindings;
        this.etag = etag;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _toJson() {
        local result = {};
        if (version) {
            result["version"] <- version;
        }
        if (bindings) {
            result["bindings"] <- bindings;
        }
        if (etag) {
            result["etag"] <- etag;
        }
        return result;
    }

    function _fromJson(jsonPolicy) {
        version = GooglePubSub._utils._getTableValue(jsonPolicy, "version", 0);
        bindings = GooglePubSub._utils._getTableValue(jsonPolicy, "bindings", []);
        etag = GooglePubSub._utils._getTableValue(jsonPolicy, "etag", null);
    }
}

// This class represents Pub/Sub Publisher.
// It allows to publish messages to a specific topic of Google Cloud Pub/Sub service.
class GooglePubSub.Publisher {
    _projectId = null;
    _oAuthTokenProvider = null;
    _topic = null;

    // GooglePubSub.Publisher constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //     topicName : string        Name of the topic to publish message to.
    //
    // Returns:                      GooglePubSub.Publisher instance created
    constructor(projectId, oAuthTokenProvider, topicName) {
        _projectId = projectId;
        _oAuthTokenProvider = oAuthTokenProvider;
        _topic = GooglePubSub._Resource(projectId, oAuthTokenProvider, _GOOGLE_PUB_SUB_TOPICS_TYPE);
        _topic.setName(topicName);
    }

    // Publish the provided message or array of messages to the topic.
    //
    // Parameters:
    //     message :                 The message(s) to be published. Can be:
    //         any type value          - a raw message value you want to publish,
    //         or array of values      - array of raw message values,
    //         or Message instance     - instance of GooglePubSub.Message class
    //                                     if you need to provide attributes for the message,
    //         or array of Messages    - array of GooglePubSub.Message instances.
    //     callback : function       Optional callback function to be executed once the messages are published.
    //         (optional)            The callback signature:
    //                               callback(error, messageIds), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //                                   messageIds :             Google Pub/Sub service assigned ID of each
    //                                     array of strings       published message, in the same order as the messages
    //                                                            in the request.
    //                                                            IDs are guaranteed to be unique within the topic.
    //
    // Returns:                      Nothing
    function publish(message, callback = null) {
        local error = GooglePubSub._utils._validateNonEmptyArg(message, "message");
        if (error) {
            _invokePublishCallback(error, null, callback);
            return;
        }
        local messages = GooglePubSub._utils._arrify(message).map(function (msg) {
            if (!(msg instanceof GooglePubSub.Message)) {
                msg = GooglePubSub.Message(msg);
            }
            error = error || msg._getError();
            return msg._toJson();
        });

        if (error) {
            _invokePublishCallback(error, null, callback);
            return;
        }

        _topic.request("POST", ":publish", { "messages" : messages }, function (error, httpResponse) {
            if (callback) {
                local messageIds = null;
                if (!error) {
                    messageIds = GooglePubSub._utils._getTableValue(httpResponse, "messageIds", null);
                }
                _invokePublishCallback(error, messageIds, callback);
            }
        }.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _invokePublishCallback(error, messageIds, callback) {
        if (callback) {
            imp.wakeup(0, function () {
                callback(error, messageIds);
            });
        }
    }
}

enum _PUB_SUB_PULL_STATE {
    STOPPED,
    IN_PROGRESS,
    STOPPING
};

// This class represents Pub/Sub Pull Subscriber.
// It allows to receive messages from a Pull Subscription of Google Cloud Pub/Sub service
// and acknowledge the received messages.
// The class provides three types of pull operation:
//   - one shot pulling - GooglePubSub.PullSubscriber.pull()
//   - periodic pulling - GooglePubSub.PullSubscriber.periodicPull()
//   - pending (waiting) pulling - GooglePubSub.PullSubscriber.pendingPull()
// Only one pull operation can be active at a time. An attempt to call a new pull operation while
// another one is active fails with PUB_SUB_ERROR.LIBRARY_ERROR error.
// Periodic and pending pulls may be canceled by a special function - GooglePubSub.PullSubscriber.stopPull().
class GooglePubSub.PullSubscriber {
    _projectId = null;
    _oAuthTokenProvider = null;
    _subscr = null;

    _periodicPullTimer = null;
    _pullState = null;

    // GooglePubSub.PullSubscriber constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //     subscrName : string       Name of the subscription to receive messages from.
    //
    // Returns:                      GooglePubSub.PullSubscriber instance created
    constructor(projectId, oAuthTokenProvider, subscrName) {
        _projectId = projectId;
        _oAuthTokenProvider = oAuthTokenProvider;
        _subscr = GooglePubSub._Resource(projectId, oAuthTokenProvider, _GOOGLE_PUB_SUB_SUBSCRIPTIONS_TYPE);
        _subscr.setName(subscrName);
        _pullState = _PUB_SUB_PULL_STATE.STOPPED;
    }

    // One shot pulling.
    // Checks for new messages and calls a callback immediately.
    // The new messages (if any) are returned in the callback (not more than maxMessages).
    // The messages are automatically acknowledged if autoAck option is set to true.
    // The callback is called in any case, even if there are no new messages.
    //
    // Only one pull operation can be active at a time. An attempt to call a new pull operation while
    // another one is active fails with PUB_SUB_ERROR.LIBRARY_ERROR error.
    //
    // Parameters:
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                   autoAck : boolean       Automatically acknowledge the message
    //                                                           once it's pulled.
    //                                                           Default: false
    //                                   maxMessages : integer   The maximum number of messages returned.
    //                                                           The Pub/Sub service may return fewer than
    //                                                           the number specified even if there are
    //                                                           more messages available.
    //                                                           Default: 20
    //     callback : function       Optional callback function to be executed once the messages
    //         (optional)            are obtained.
    //                               The callback signature:
    //                               callback(error, messages), where
    //                                   error :                 Error details,
    //                                     GooglePubSub.Error    null if the operation succeeds.
    //                                   messages : array of     Messages returned.
    //                                     GooglePubSub.Message
    //
    // Returns:                      Nothing
    function pull(options = null, callback = null) {
        if (_checkPullState(callback)) {
            _pull(options, true, true, callback);
        }
    }

    // Periodic pulling.
    // Periodically checks for new messages and calls a callback if new messages are available
    // at a time of a check.
    // The new messages are returned in the callback (not more than maxMessages).
    // The messages are automatically acknowledged if autoAck option is set to true.
    // The callback is not called when there are no new messages at a time of a check.
    //
    // Only one pull operation can be active at a time. An attempt to call a new pull operation while
    // another one is active fails with PUB_SUB_ERROR.LIBRARY_ERROR error.
    //
    // Parameters:
    //     period : float            Period of checks, in seconds, must be positive float value.
    //                               The specified period should not be too small, otherwise
    //                               a number of http requests per second will exceed Electric Imp
    //                               maximum rate limit and further requests will fail with
    //                               PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED error.
    //                               For more information about http requests rate limiting see
    //                               https://electricimp.com/docs/api/httprequest/
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                   autoAck : boolean       Automatically acknowledge the message
    //                                                           once it's pulled.
    //                                                           Default: false
    //                                   maxMessages : integer   The maximum number of messages returned.
    //                                                           The Pub/Sub service may return fewer than
    //                                                           the number specified even if there are
    //                                                           more messages available.
    //                                                           Default: 20
    //     callback : function       Optional callback function to be executed once the messages
    //         (optional)            are obtained.
    //                               The callback signature:
    //                               callback(error, messages), where
    //                                   error :                 Error details,
    //                                     GooglePubSub.Error    null if the operation succeeds.
    //                                   messages : array of     Messages returned.
    //                                     GooglePubSub.Message
    //
    // Returns:                      Nothing
    function periodicPull(period, options = null, callback = null) {
        local error = GooglePubSub._utils._validatePositiveArg(period, "period", null);
        if (error) {
            _invokePullCallback(error, null, false, callback);
            return;
        }
        if (_checkPullState(callback)) {
            _pullState = _PUB_SUB_PULL_STATE.IN_PROGRESS;
            _periodicPull(period, options, callback);
        }
    }

    // Pending (waiting) pulling.
    // Waits for new messages and calls a callback when new messages appear.
    // The new messages are returned in the callback (not more than maxMessages).
    // The messages are automatically acknowledged if autoAck option is set to true.
    // The callback is called only when new messages are available (or in case of an error).
    //
    // Only one pull operation can be active at a time. An attempt to call a new pull operation while
    // another one is active fails with PUB_SUB_ERROR.LIBRARY_ERROR error.
    //
    // Parameters:
    //     options : table           Optional Key/Value settings.
    //         (optional)            The valid keys are:
    //                                   repeat : boolean        If true, a new pendingPull() function
    //                                                           with the same parameters is automatically
    //                                                           called after the callback is executed.
    //                                                           Default: false
    //                                   autoAck : boolean       Automatically acknowledge the message
    //                                                           once it's pulled.
    //                                                           Default: false
    //                                   maxMessages : integer   The maximum number of messages returned.
    //                                                           The Pub/Sub system may return fewer than
    //                                                           the number specified even if there are
    //                                                           more messages available.
    //                                                           Default: 20
    //     callback : function       Optional callback function to be executed once the messages
    //         (optional)            are obtained.
    //                               The callback signature:
    //                               callback(error, messages), where
    //                                   error :                 Error details,
    //                                     GooglePubSub.Error    null if the operation succeeds.
    //                                   messages : array of     Messages returned.
    //                                     GooglePubSub.Message
    //
    // Returns:                      Nothing
    function pendingPull(options = null, callback = null) {
        if (_checkPullState(callback)) {
            _pullState = _PUB_SUB_PULL_STATE.IN_PROGRESS;
            _pull(options, false, false, callback);
        }
    }

    // Stops periodic or pending pull operation if it was started by
    // GooglePubSub.PullSubscriber.periodicPull() or GooglePubSub.PullSubscriber.pendingPull() earlier.
    // Does nothing if no periodic or pending pull operation is active at this moment.
    //
    // Returns:                      Nothing
    function stopPull() {
        if (_pullState == _PUB_SUB_PULL_STATE.IN_PROGRESS) {
            _pullState = _PUB_SUB_PULL_STATE.STOPPING;
            if (_periodicPullTimer) {
                imp.cancelwakeup(_periodicPullTimer);
                _periodicPullTimer = null;
                _pullState = _PUB_SUB_PULL_STATE.STOPPED;
            }
            if (_subscr.stopPullRequest()) {
                _pullState = _PUB_SUB_PULL_STATE.STOPPED;
            }
        }
    }

    // Acknowledges to the Google Pub/Sub service that the message(s) was received.
    // Acknowledging a message whose ack deadline has expired may succeed, but such a message may be
    // redelivered later.
    // Acknowledging a message more than once will not result in an error.
    //
    // Parameters:
    //     message :                 The message(s) being acknowledged. Can be:
    //         GooglePubSub.Message    - GooglePubSub.Message instance,
    //         or string               - acknowledgment ID of a message,
    //         or array of Message     - array of GooglePubSub.Message instances,
    //         or array of string      - array of acknowledgment IDs.
    //                               Messages or acknowledgment IDs are returned by any PullSubscriber
    //                               pull methods.
    //     callback : function       Optional callback function to be executed once the messages
    //         (optional)            are acknowledged. The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function ack(message, callback = null) {
        local error = GooglePubSub._utils._validateNonEmptyArg(message, "message");
        if (error) {
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
            return;
        }
        _subscr.request(
            "POST",
            ":acknowledge",
            { "ackIds" : _getAckIds(message) },
            function (error, httpResponse) {
                GooglePubSub._utils._invokeDefaultCallback(error, callback);
            }.bindenv(this));
    }

    // Modifies the ack deadline for a specific message(s).
    // This method is useful to indicate that more time is needed to process a message by the subscriber,
    // or to make the message available for redelivery if the processing was interrupted.
    //
    // Parameters:
    //     message :                 The message(s) whose ack deadline is being modified. Can be:
    //         GooglePubSub.Message    - GooglePubSub.Message instance,
    //         or string               - acknowledgment ID of a message,
    //         or array of Message     - array of GooglePubSub.Message instances,
    //         or array of string      - array of acknowledgment IDs.
    //                               Messages or acknowledgment IDs are returned by any PullSubscriber
    //                               pull methods.
    //     ackDeadlineSeconds :      The new ack deadline.
    //         integer
    //     callback : function       Optional callback function to be executed once the ack deadline
    //         (optional)            is modified. The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function modifyAckDeadline(message, ackDeadlineSeconds, callback = null) {
        local error = GooglePubSub._utils._validateNonEmptyArg(message, "message") ||
            GooglePubSub._utils._validatePositiveArg(ackDeadlineSeconds, "ackDeadlineSeconds");
        if (error) {
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
            return;
        }
        local body = {
            "ackIds" : _getAckIds(message),
            "ackDeadlineSeconds" : ackDeadlineSeconds
        };
        _subscr.request("POST", ":modifyAckDeadline", body, function (error, httpResponse) {
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
        }.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _checkPullState(callback) {
        if (_pullState != _PUB_SUB_PULL_STATE.STOPPED) {
            _invokePullCallback(
                GooglePubSub.Error(PUB_SUB_ERROR.LIBRARY_ERROR, GOOGLE_PUB_SUB_PULL_IN_PROGRESS),
                null, false, callback);
            return false;
        }
        return true;
    }

    function _periodicPull(period, options = null, callback = null) {
        _periodicPullTimer = imp.wakeup(period, function () {
            _periodicPull(period, options, callback);
        }.bindenv(this));
        _pull(options, true, false, callback);
    }

    function _isStopPull() {
        if (_pullState == _PUB_SUB_PULL_STATE.STOPPING) {
            _pullState = _PUB_SUB_PULL_STATE.STOPPED;
            return true;
        }
        return false;
    }

    function _pull(options, returnImmediately, returnEmptyMsgs, callback = null) {
        if (_isStopPull()) {
            return;
        }
        local maxMessages = GooglePubSub._utils._getTableValue(options, "maxMessages", _GOOGLE_PUB_SUB_PULL_MAX_MESSAGES_DEFAULT);
        local error = GooglePubSub._utils._validatePositiveArg(maxMessages, "maxMessages");
        if (error) {
            _invokePullCallback(error, null, returnEmptyMsgs, callback);
            return;
        }
        local autoAck = GooglePubSub._utils._getTableValue(options, "autoAck", false);
        local body = {
            "returnImmediately" : returnImmediately,
            "maxMessages" : maxMessages
        };
        _subscr.request("POST", ":pull", body, function (error, httpResponse) {
            if (_isStopPull()) {
                return;
            }
            local messages = null;
            if (!error) {
                messages = GooglePubSub._utils._getTableValue(httpResponse, "receivedMessages", []).map(function (value) {
                    local msg = GooglePubSub.Message();
                    msg._fromJson(value);
                    error = error || msg._getError();
                    return msg;
                });
            }
            if (!error && autoAck && messages.len() > 0) {
                ack(messages, function (ackError) {
                    _invokePullCallback(ackError, messages, returnEmptyMsgs, callback);
                }.bindenv(this));
            }
            else {
                _invokePullCallback(error, messages, returnEmptyMsgs, callback);
            }

            // re-queue pending pull
            if (!returnImmediately) {
                if (GooglePubSub._utils._getTableValue(options, "repeat", false) || !error && messages.len() == 0) {
                    imp.wakeup(0, function () {
                        _pull(options, returnImmediately, returnEmptyMsgs, callback);
                    }.bindenv(this));
                }
                else {
                    _pullState = _PUB_SUB_PULL_STATE.STOPPED;
                }
            }
        }.bindenv(this), true);
    }

    function _invokePullCallback(error, messages, returnEmptyMsgs, callback) {
        if (callback && (error || returnEmptyMsgs || messages && messages.len() > 0)) {
            imp.wakeup(0, function () {
                callback(error, error ? null : messages);
            });
        }
    }

    function _getAckIds(messages) {
        return GooglePubSub._utils._arrify(messages).map(function (value) {
            if (value instanceof GooglePubSub.Message) {
                return value.ackId;
            }
            return value;
        });
    }
}

// This class represents Pub/Sub Push Subscriber.
// It allows to receive messages from a Push Subscription configured with push endpoint URL
// based on imp Agent URL.
class GooglePubSub.PushSubscriber {
    static _pushSubscribers = {};

    _projectId = null;
    _oAuthTokenProvider = null;
    _subscrName = null;
    _subscrs = null;

    // GooglePubSub.PushSubscriber constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //     subscrName : string       Name of the subscription to receive messages from.
    //
    // Returns:                      GooglePubSub.PushSubscriber instance created
    constructor(projectId, oAuthTokenProvider, subscrName) {
        _projectId = projectId;
        _oAuthTokenProvider = oAuthTokenProvider;
        _subscrName = subscrName;
        _subscrs = GooglePubSub.Subscriptions(projectId, oAuthTokenProvider);
        http.onrequest(_pushRequestHandler.bindenv(this));
    }

    // Checks if the subscription is configured with push endpoint URL
    // based on imp Agent URL
    // and sets the specified handler function to be executed every time
    // incoming messages for the subscription are received from Google Pub/Sub service.
    // If the subscription is not configured with an appropriate URL,
    // the callback is executed with PUB_SUB_ERROR.LIBRARY_ERROR error.
    //
    // Parameters:
    //     messagesHandler :         Handler function to be executed when incoming messages
    //         function              are received.
    //                               The messagesHandler signature:
    //                               messagesHandler(error, messages), where
    //                                   error :                  Error details (used in the case when
    //                                     GooglePubSub.Error     the received messages have incorrect format
    //                                                            - PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE
    //                                                            error is reported).
    //                                                            Null, if the received messages are correct.
    //                                   messages : array of      Messages received.
    //                                     GooglePubSub.Message
    //     callback : function       Optional callback function to be executed once the subscription
    //         (optional)            is obtained and checked. The callback signature:
    //                               callback(error), where
    //                                   error :                  Error details,
    //                                     GooglePubSub.Error     null if the operation succeeds.
    //
    // Returns:                      Nothing
    function setMessagesHandler(messagesHandler, callback = null) {
        local error = GooglePubSub._utils._validateNonEmptyArg(messagesHandler, "messagesHandler");
        if (error) {
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
            return;
        }
        _subscrs.obtain(_subscrName, null, function(error, subscrConfig) {
            if (!error) {
                local pushConfig = subscrConfig.pushConfig;
                if (!pushConfig) {
                    error = GooglePubSub.Error(PUB_SUB_ERROR.LIBRARY_ERROR, GOOGLE_PUB_SUB_PUSH_SUBSCR_REQUIRED);
                }
                else if (pushConfig.pushEndpoint.find(http.agenturl()) != 0) {
                    error = GooglePubSub.Error(PUB_SUB_ERROR.LIBRARY_ERROR, GOOGLE_PUB_SUB_INTERNAL_PUSH_REQUIRED);
                }
                else {
                    _pushSubscribers[_subscrs._subscr.getResourceName()] <- [ pushConfig.pushEndpoint, messagesHandler ];
                }
            }
            GooglePubSub._utils._invokeDefaultCallback(error, callback);
        }.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _pushRequestHandler(request, response) {
        if (_pushSubscribers.len() == 0) {
            return;
        }
        try {
            local endpoint = http.agenturl();
            if (request.path.len() > 0) {
                endpoint += request.path;
            }
            local token = GooglePubSub._utils._getTableValue(request.query, "token", null);
            if (token) {
                endpoint = format("%s?token=%s", endpoint, token);
            }
            local body = http.jsondecode(request.body);
            local subscrName = GooglePubSub._utils._getTableValue(body, "subscription", null);
            if (request.method == "POST" && subscrName &&
                subscrName in _pushSubscribers && endpoint == _pushSubscribers[subscrName][0]) {
                local messagesHandler = _pushSubscribers[subscrName][1];
                local message = GooglePubSub.Message();
                message._fromJson(body, false);
                response.send(200, "OK");
                imp.wakeup(0, function () {
                    messagesHandler(message._getError(), [message]);
                });
                return;
            }
            response.send(404, "ERROR");
        } catch (ex) {
            response.send(500, "ERROR");
        }
    }
}

// This class represents Pub/Sub Message:
// the combination of any format data and optional attributes that a publisher sends to a topic and
// subscriber(s) receive.
class GooglePubSub.Message {
    // ID of the message
    id = null;
    // ID used to acknowledge the message receiving
    ackId = null;
    // message data of any type
    data = null;
    // Optional message attributes:
    // a key-value table of additional information that a publisher can define for a message.
    attributes = null;
    // The time at which the message was published to the Google Cloud Pub/Sub service.
    // Format is RFC3339 UTC "Zulu", accurate to nanoseconds, e.g. "2014-10-02T15:01:23.045123456Z"
    publishTime = null;

    _error = null;

    // Message constructor that can be used for message publishing.
    // The message must contain either a non-empty data field, or at least one attribute.
    // Otherwise GooglePubSub.Publisher.publish() method will fail with
    // PUB_SUB_ERROR.LIBRARY_ERROR error.
    //
    // Parameters:
    //     data : any type value     The message data.
    //         (optional)
    //     attributes : table        Optional message attributes.
    //         (optional)
    //
    // Returns:                      Message object that can be send to Pub/Sub using
    //                               GooglePubSub.Publisher.publish() method.
    constructor(data = null, attributes = null) {
        this.data = data;
        this.attributes = attributes;

        _error = GooglePubSub._utils._validateNonEmptyArg(data, "data", false) &&
            GooglePubSub._utils._validateNonEmptyArg(attributes, "attributes", false);
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _toJson() {
        local result = {};
        if (data != null) {
            result["data"] <- http.base64encode(http.jsonencode(data));
        }
        if (attributes != null) {
            result["attributes"] <- attributes;
        }
        return result;
    }

    function _fromJson(jsonMessage, checkAckId = true) {
        _error = null;
        local errDetails = null;
        ackId = GooglePubSub._utils._getTableValue(jsonMessage, "ackId", null);
        local message = GooglePubSub._utils._getTableValue(jsonMessage, "message", null);
        id = GooglePubSub._utils._getTableValue(message, "messageId", null);
        publishTime = GooglePubSub._utils._getTableValue(message, "publishTime", null);
        local messageData = GooglePubSub._utils._getTableValue(message, "data", null);
        if (messageData) {
            try {
                data = http.jsondecode(http.base64decode(messageData).tostring());
            }
            catch (e) {
                errDetails = e;
            }
        }
        attributes = GooglePubSub._utils._getTableValue(message, "attributes", null);

        if (!_error && checkAckId && GooglePubSub._utils._isEmpty(ackId)) {
            errDetails = format("%s: %s", GOOGLE_PUB_SUB_NON_EMPTY_ARG, "ackId");
        }
        _error = errDetails ?
            GooglePubSub.Error(PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE, errDetails, jsonMessage) :
            null;
    }

    function _getError() {
        return _error;
    }
}

// Internal auxiliary class, provides access to Pub/Sub resource (topic or subscription)
// manipulation methods.
class GooglePubSub._Resource {
    _projectId = null;
    _oAuthTokenProvider = null;
    _projectName = null;

    _resourceType = null;
    _resourceName = null;
    _resourceUrl = null;

    _currPullRequest = null;

    _initError = null;

    constructor(projectId, oAuthTokenProvider, type) {
        _projectId = projectId;
        _projectName = projectId ? format("projects/%s", projectId) : "";
        _oAuthTokenProvider = oAuthTokenProvider;
        _resourceType = type;
        _initError = GooglePubSub._utils._validateNonEmptyArg(projectId, "projectId") ||
            GooglePubSub._utils._validateNonEmptyArg(oAuthTokenProvider, "oAuthTokenProvider", false);
    }

    function setName(name) {
        _setResourceName(GooglePubSub._utils._isEmpty(name) ?
            null :
            format("%s/%s/%s", _projectName, _resourceType, name));
    }

    function getResourceName() {
        return _resourceName;
    }

    function getResourceUrl() {
        return _resourceUrl;
    }

    function getName(resourceName) {
        if (resourceName) {
            local names = split(resourceName, "/");
            if (names.len() == 4 &&
                names[0] == "projects" && names[1] == _projectId &&
                names[2] == _resourceType) {
                return names[3];
            }
        }
        return null;
    }

    function obtain(options, createBody, callback) {
        local autoCreate = GooglePubSub._utils._getTableValue(options, "autoCreate", false);
        local resourceName = _resourceName;
        get(function (error, httpResponse) {
                if (autoCreate &&
                    error && error.type == PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED &&
                    error.httpStatus == 404) {
                    _setResourceName(resourceName);
                    create(createBody, callback);
                }
                else {
                    _invokeCallback(error, httpResponse, callback);
                }
            }.bindenv(this),
            !autoCreate);
    }

    function create(body, callback) {
        _processRequest("PUT", _resourceUrl, body, callback);
    }

    function get(callback, logError = true) {
        _processRequest("GET", _resourceUrl, null, callback, logError);
    }

    function remove(callback) {
        _processRequest("DELETE", _resourceUrl, null, callback);
    }

    function list(options, callback) {
        _list(format("%s/%s", _GOOGLE_PUB_SUB_BASE_URL, _projectName), options, false, callback);
    }

    function getIamPolicy(callback) {
        request("GET", ":getIamPolicy", null, callback);
    }

    function setIamPolicy(policy, callback) {
        request("POST", ":setIamPolicy", { "policy" : policy }, callback);
    }

    function testIamPermissions(permissions, callback) {
        permissions = GooglePubSub._utils._arrify(permissions);
        request("POST", ":testIamPermissions", { "permissions" : permissions }, callback);
    }

    function request(method, urlSuffix, body, callback, isPull = false) {
        _processRequest(method, _resourceUrl ? format("%s%s", _resourceUrl, urlSuffix) : null, body, callback, true, isPull);
    }

    function stopPullRequest() {
        if (_currPullRequest) {
            _currPullRequest.cancel();
            _currPullRequest = null;
            return true;
        }
        return false;
    }

    function _setResourceName(resourceName) {
        if (GooglePubSub._utils._isEmpty(resourceName)) {
            _resourceName = null;
            _resourceUrl = null;
        }
        else {
            _resourceName = resourceName;
            _resourceUrl = format("%s/%s", _GOOGLE_PUB_SUB_BASE_URL, _resourceName);
        }
    }

    function _list(baseUrl, options, isSubResourcesList, callback) {
        if (GooglePubSub._utils._getTableValue(options, "paginate", false)) {
            _listRequest(baseUrl, options, isSubResourcesList, callback);
        }
        else {
            _listAll([], baseUrl, options, isSubResourcesList, callback);
        }
    }

    function _listRequest(baseUrl, options, isSubResourcesList, callback) {
        local paginate = GooglePubSub._utils._getTableValue(options, "paginate", false);
        local pageSize = paginate ?
            GooglePubSub._utils._getTableValue(options, "pageSize", _GOOGLE_PUB_SUB_LIST_PAGE_SIZE_DEFAULT) :
            _GOOGLE_PUB_SUB_LIST_PAGE_SIZE_DEFAULT;
        local error = GooglePubSub._utils._validatePositiveArg(pageSize, "pageSize");
        if (error) {
            _invokeListCallback(error, null, null, options, callback);
            return;
        }

        local url = format("%s/%s?pageSize=%d", baseUrl, _resourceType, pageSize);
        local pageToken = GooglePubSub._utils._getTableValue(options, "pageToken", null);
        if (pageToken) {
            url = format("%s&pageToken=%s", url, pageToken);
        }

        _processRequest("GET", url, null, function (error, httpResponse) {
            local resourceNames = [];
            if (!error) {
                local resources = GooglePubSub._utils._getTableValue(httpResponse, _resourceType, null);
                if (resources) {
                    resourceNames = resources.map(function (resource) {
                        local fullName = isSubResourcesList ?
                            resource :
                            GooglePubSub._utils._getTableValue(resource, "name", null);
                        local result = getName(fullName);
                        if (!result) {
                            error = error || GooglePubSub.Error(
                                PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE,
                                format("%s %s", GOOGLE_PUB_SUB_INVALID_FORMAT, "resource name"),
                                httpResponse);
                        }
                        return result;
                    }.bindenv(this));
                }
            }
            _invokeListCallback(error, httpResponse, resourceNames, options, callback);
        }.bindenv(this));
    }

    function _listAll(result, baseUrl, options, isSubResourcesList, callback) {
        _listRequest(baseUrl, options, isSubResourcesList,
            function (error, resourceNames, nextOptions) {
                if (!error) {
                    result.extend(resourceNames);
                    if (nextOptions) {
                        _listAll(result, baseUrl, nextOptions, isSubResourcesList, callback);
                    }
                }
                if (error || !nextOptions) {
                    _invokeListCallback(error, null, result, options, callback);
                }
            }.bindenv(this));
    }

    function _invokeListCallback(error, httpResponse, resourceNames, options, callback) {
        if (callback) {
            local nextOptions = null;
            if (!error) {
                local nextPageToken = GooglePubSub._utils._getTableValue(httpResponse, "nextPageToken", null);
                if (nextPageToken) {
                    nextOptions = options ? clone(options) : {};
                    nextOptions["pageToken"] <- nextPageToken;
                }
            }
            imp.wakeup(0, function () {
                callback(error, error ? null : resourceNames, nextOptions);
            });
        }
    }

    function _processRequest(method, url, body, callback, logError = true, isPull = false) {
        local error = _initError ||
            GooglePubSub._utils._validateNonEmptyArg(url,
                format("%sName", _resourceType == _GOOGLE_PUB_SUB_TOPICS_TYPE ? "topic" : "subscr"));
        if (error) {
            _invokeCallback(error, null, callback);
            return;
        }

        _oAuthTokenProvider.acquireAccessToken(function (token, error) {
            if (error) {
                _invokeCallback(GooglePubSub.Error(PUB_SUB_ERROR.LIBRARY_ERROR,
                    format("%s: %s", GOOGLE_PUB_SUB_TOKEN_ACQUISITION_ERROR, error),
                    null, callback));
            }
            else {
                local headers = {
                    "Authorization" : format("Bearer %s", token),
                    "Content-Type" : "application/json"
                };

                GooglePubSub._utils._logDebug(format("Doing the request: %s %s, body: %s", method, url, http.jsonencode(body)));

                local request = http.request(method, url, headers, body ? http.jsonencode(body) : "");
                if (isPull) {
                    _currPullRequest = request;
                }
                request.sendasync(function (response) {
                    _processResponse(response, callback, logError, isPull);
                }.bindenv(this));
            }
        }.bindenv(this));
    }

    function _processResponse(response, callback, logError = true, isPull = false) {
        if (isPull) {
            _currPullRequest = null;
        }
        GooglePubSub._utils._logDebug(format("Response status: %d, body: %s", response.statuscode, response.body));

        local errType = null;
        local errDetails = null;
        local httpStatus = response.statuscode;
        if (httpStatus < 200 || httpStatus >= 300) {
            errType = PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED;
            errDetails = format("%s: %i", GOOGLE_PUB_SUB_REQUEST_FAILED, httpStatus);
        }
        try {
            response.body = (response.body == "") ? {} : http.jsondecode(response.body);
        } catch (e) {
            if (!errType) {
                errType = PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE;
                errDetails = e;
            }
        }
        _invokeCallback(errType ? GooglePubSub.Error(errType, errDetails, response.body, httpStatus, logError) : null,
            response.body, callback);
    }

    function _invokeCallback(error, httpResponse, callback) {
        if (callback) {
            imp.wakeup(0, function () {
                callback(error, httpResponse);
            });
        }
    }
}
