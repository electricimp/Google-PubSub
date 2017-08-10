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

class GooglePubSub {
    static VERSION = "1.0.0";

    // Enables/disables the library debug output (including errors logging).
    // Disabled by default.
    //
    // Parameters:
    //     value : boolean           true to enable, false to disable
    function setDebug(value) {
    }
}

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
}

// This class provides access to Pub/Sub Topics manipulation methods.
// It can be used to check existence, create, delete topics of the specified Project
// and obtain a list of the topics registered to the Project.
class GooglePubSub.Topics {
    // GooglePubSub.Topics constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //                                         
    // Returns:                      GooglePubSub.Topics instance created
    constructor(projectId, oAuthTokenProvider) {
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
    }

    // Provides Identity and Access Management (IAM) functionality for topics.
    // (see GooglePubSub.IAM class description for details)
    //
    // Returns:                      An instance of IAM class that can be used for execution of 
    //                               IAM methods for a specific topic.
    function iam() {
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
    // GooglePubSub.Subscriptions constructor.
    //
    // Parameters:
    //     projectId : string        Google Cloud Project ID.
    //     oAuthTokenProvider        Provider of access tokens suitable for Google Pub/Sub service requests
    //                               authentication.
    //                                         
    // Returns:                      GooglePubSub.Subscriptions instance created
    constructor(projectId, oAuthTokenProvider) {
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
    }

    // Provides Identity and Access Management (IAM) functionality for subscriptions.
    // (see GooglePubSub.IAM class description for details)
    //
    // Returns:                      An instance of IAM class that can be used for execution of 
    //                               IAM methods for a specific subscription.
    function iam() {
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
    constructor(topicName, ackDeadlineSeconds = 10, pushConfig = null) {
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
    }
}

// This class represents Pub/Sub Publisher.
// It allows to publish messages to a specific topic of Google Cloud Pub/Sub service.
class GooglePubSub.Publisher {
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
    }
}

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
    function pull(options = null, callback = null)

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
    function periodicPull(period, options = null, callback = null)

    // Pending (waiting) pulling.
    // Waits for new messages and calls a callback when new messages are appeared.
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
    function pendingPull(options = null, callback = null)

    // Stops periodic or pending pull operation if it was started by 
    // GooglePubSub.PullSubscriber.periodicPull() or GooglePubSub.PullSubscriber.pendingPull() earlier.
    // Does nothing if no periodic or pending pull operation is active at this moment.
    //
    // Returns:                      Nothing
    function stopPull() {
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
    }
}

// This class represents Pub/Sub Push Subscriber.
// It allows to receive messages from a Push Subscription configured with push endpoint URL
// based on imp Agent URL.
class GooglePubSub.PushSubscriber {
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
    }
}
