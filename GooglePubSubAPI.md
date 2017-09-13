# Google PubSub Library API

## GooglePubSub

### setDebug(*value*)

This method enables (*value* = `true`) or disables (*value* = `false`) the library debug output (including error logging). It is disabled by default and returns nothing.

## GooglePubSub.Error

Represents an error returned by the library and has the following public properties:

- *type* &mdash; The error type, which will be one of the following *PUB_SUB_ERROR* enum values:
  - *PUB_SUB_ERROR.LIBRARY_ERROR* &mdash; The library is wrongly initialized, or a method is called with invalid argument(s), or an internal error. The error details can be found in the *details* properties.
  - *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* &mdash; HTTP request to Google Cloud Pub/Sub service fails. The error details can be found in the *details*, *httpStatus* and *httpResponse* properties.
  - *PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE* &mdash; An unexpected response from Google Pub/Sub service. The error details can be found in the *details* and *httpResponse* properties.
- *details* &mdash; A string providing error details.
- *httpStatus* &mdash; An integer indicating the HTTP status code, or `null` if *type* is *PUB_SUB_ERROR.LIBRARY_ERROR*
- *httpResponse* &mdash; A table of key-value strings holding the response body of the failed request, or `null` if *type* is *PUB_SUB_ERROR.LIBRARY_ERROR*.

## GooglePubSub.Message

Represents a Google Pub/Sub Message: a combination of data of any type and optional attributes that a publisher sends to a topic. It has the following public properties:

- *id* &mdash; The ID of the message as a string.
- *ackId* &mdash; The ID used to acknowledge receipt of the message. A string.
- *data* &mdash; The message data. May be any data type.
- *attributes* &mdash; A table of key-value strings holding optional attributes of the message.
- *publishTime* &mdash; The time when the message was published to the Google Cloud Pub/Sub service, as a string. The format is RFC3339 UTC ‘Zulu’, accurate to nanoseconds, eg. `"2014-10-02T15:01:23.045123456Z"`.

### Constructor: GooglePubSub.Message(*[data][, attributes]*)

Creates a message that can be published. The message must contain either a non-empty *data* field, or at least one attribute. Otherwise *GooglePubSub.Publisher.publish()* method will fail with *PUB_SUB_ERROR.LIBRARY_ERROR* error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | Any | Optional | The message data |
| *attributes* | Table of key-value strings | Optional | The message attributes |

## GooglePubSub.Topics

Helps your code manage topics.

### Constructor: GooglePubSub.Topics(*projectId, oAuthTokenProvider*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes | The ID of a Google Cloud Project |
| *oAuthTokenProvider* | Object | Yes | The provider of access tokens suitable for Google Pub/Sub service requests authentication. See [here](/README.md#access-token-provider) for more information |

### obtain(*topicName[, options][, callback]*)

Checks if the specified topic exists. If the topic does not exist and the *autoCreate* option is `true`, the topic is created.
If the topic does not exist and the *autoCreate* option is `false`, the method fails with a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *topicName* | String | Yes | The name of the topic |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*autoCreate* &mdash; A boolean indicating whether the topic should be created if it does not exist. Default: `false` |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

### remove(*topicName[, callback]*)

Deletes the specified topic, if it exists. If it doesn’t, the operation fails with s *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

Existing subscriptions related to the deleted topic are not destroyed.

After the topic is deleted, a new topic may be created with the same name; this will be an entirely new topic with none of the old configuration or subscriptions.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *topicName* | String | Yes | The unique name of the topic |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

### list(*[options][, callback])*

Get a list of the names of all topics registered to the project.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*paginate* &mdash; a boolean indicating whether the operation returns a limited number of topics (up to *pageSize*) and a new *pageToken* which allows to obtain the next page of data, or the entire list of topics (`false`). Default: `false`.<br>*pageSize* &mdash; An integer specifying the maximum number of topics to return. If *paginate* is `false`, this option is ignored. Default: 20.<br>*pageToken* &mdash; A string containing the page token returned by the previous paginated *list()* call; indicates that the library should return the next page of data. If *paginate* is `false`, this option is ignored. If *paginate* is `true` and *pageToken* is not specified, the library starts listing from the beginning |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *error* | GooglePubSub.Error | Yes | Error details, or `null` if the operation succeeds |
| *topicNames* | Array of strings | Yes | The names of the topics |
| *nextOptions* | Table of key-value strings | Optional | An *options* table that can be directly used as an argument for a subsequent paginated *list()* call; it contains *pageToken* returned by the currently executed *list()* call. *nextOptions* is `null` if no more results are available, the *paginate* option was `false` or the operation fails |

### iam()

Returns an instance of the GooglePubSub.IAM class that can be used for execution of Identity and Access Management methods for topics.

## GooglePubSub.Publisher

Allows your code to publish messages to a specific topic.

### Constructor: GooglePubSub.Publisher(*projectId, oAuthTokenProvider, topicName*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId | String | Yes  | The project’s ID |
| *oAuthTokenProvider* | Object | Yes | The provider of access tokens suitable for Google Pub/Sub service requests authentication. See [here](/README.md#access-token-provider) for more information |
| *topicName* | String | Yes | The name of the topic to publish message to |

### publish(*message[, callback]*)

Publishes the provided message, or array of messages, to the topic.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *message* | Various | Yes | The message(s) to be published. It can be:
  - any type - raw data value
  - array of any type - array of raw data values
  - GooglePubSub.Message instance
  - array of GooglePubSub.Message instances |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *error* | GooglePubSub.Error | Yes | Error details, or `null` if the operation succeeds |
| *messageIds* | Array of strings | Optional | Google Pub/Sub service IDs of each published message, in the same order as the messages in the request. IDs are guaranteed to be unique within the topic |

## GooglePubSub.SubscriptionConfig

Represents a Google Pub/Sub subscription’s configuration and has the following public properties:

- *topicName* &mdash; The name of the Google Pub/Sub topic from which this subscription receives messages, as a string.
- *ackDeadlineSeconds* &mdash; An integer holding the maximum time (in seconds) after receiving a message when the message must be acknowledged before it is redelivered by the Pub/Sub service.
- *pushConfig* &mdash; An instance of GooglePubSub.PushConfig which holds additional configuration for push subscription, or `null` for pull subscriptions.

### Constructor: GooglePubSub.SubscriptionConfig(*topicName, ackDeadlineSeconds, pushConfig*)

Creates a subscription configuration that can be used to crete a new subscription.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *topicName* | String* | Yes | The name of the topic from which this subscription receives messages |
| *ackDeadlineSeconds* | Integer | Optional | The maximum time (in seconds) after receiving a message when the message must be acknowledged before it is redelivered by the Pub/Sub service. Default: 10 seconds |
| *pushConfig* | GooglePubSub.PushConfig | Optional | Additional configuration for push subscription. Default: `null` (ie. pull subscription) |

## GooglePubSub.PushConfig

Represents the additional configuration details required by a push subscription. It has the following public properties:

- *pushEndpoint* &mdash; A string containing the URL of the endpoint that messages should be pushed to.
- *attributes* &mdash; A table* of key-value strings holding [push endpoint attributes](https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.subscriptions#PushConfig). May be `null`.

### Constructor: GooglePubSub.PushConfig(*pushEndpoint, attributes*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *pushEndpoint* | String | Yes | The push endpoint URL |
| *attributes* | Table of key-value strings | Optional | [Push endpoint attributes](https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.subscriptions#PushConfig) |

## GooglePubSub.Subscriptions

Allows your code to manage subscriptions.

### Constructor: GooglePubSub.Subscriptions(*projectId, oAuthTokenProvider*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId | String | Yes  | The project’s ID |
| *oAuthTokenProvider* | Object | Yes | The provider of access tokens suitable for Google Pub/Sub service requests authentication. See [here](/README.md#access-token-provider) for more information |

### obtain(*subscriptionName[, options][, callback]*)

Obtains the specified subscription. If a subscription with the specified name exists, the method retrieves its configuration. If  a subscription with the specified name doesn’t exist, and the *autoCreate* option is `true`, the subscription is created. In this case, the *subscrConfig* option must be specified. If the subscription does not exist and *autoCreate* is `false`, the method fails with a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *subscriptionName* | String | Yes | The unique name of the subscription |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*autoCreate* &mdash; a boolean indicating whether the subscription should be created if it does not exist. Default: `false`<br>*subscrConfig* &mdash; a GooglePubSub.SubscriptionConfig instance holding configuration of the subscription to be created. If *autoCreate* is `true`, *subscrConfig* must be specified. Otherwise, *subscrConfig* is ignored |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *error* | GooglePubSub.Error | Yes | Error details, or `null` if the operation succeeds |
| *subscrConfig* | GooglePubSub.SubscriptionConfig | Yes | The configuration of the obtained subscription |

### modifyPushConfig(*subscriptionName, pushConfig[, callback]*)

This method may be used to change a push subscription to a pull one or vice versa, or to change the push endpoint URL and other attributes of a push subscription. To modify a push subscription to a pull one, pass `null` or an empty table as the value of the *pushConfig* parameter.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *subscriptionName* | String | Yes | The unique name of the subscription |
| *pushConfig* | GooglePubSub.PushConfig | Yes | A new push configuration for future deliveries. `null` or an empty table indicates that the Pub/Sub service should stop pushing messages from the given subscription and allow messages to be pulled and acknowledged |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

### remove(*subscriptionName[, callback]*)

Deletes the specified subscription, if it exists. Otherwise it fails with a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

All messages retained in the subscription are immediately dropped and cannot be delivered by any means.

After the subscription is deleted, a new one may be created with the same name. The new subscription has no association with the old one or its topic unless the same topic is specified for the new subscription.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *subscriptionName* | String | Yes | The unique name of the subscription |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

### list(*[options][, callback]*)

Gets a list of the names of all subscriptions registered to the project or related to the specified topic.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table of key-value *strings | Optional | The valid keys (options) are:<br>*topicName* &mdash; A string with name of the topic to list subscriptions from. If not specified, the method lists all subscriptions registered to the project.<br>*paginate* &mdash; a boolean indicating whether the operation returns a limited number of topics (up to *pageSize*) and a new *pageToken* which allows to obtain the next page of data, or the entire list of topics (`false`). Default: `false`.<br>*pageSize* &mdash; An integer specifying the maximum number of topics to return. If *paginate* is `false`, this option is ignored. Default: 20.<br>*pageToken* &mdash; A string containing the page token returned by the previous paginated *list()* call; indicates that the library should return the next page of data. If *paginate* is `false`, this option is ignored. If *paginate* is `true` and *pageToken* is not specified, the library starts listing from the beginning |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *error* | GooglePubSub.Error | Yes | Error details, or `null` if the operation succeeds |
| *subscrNames* | Array of strings | Yes | The names of the subscriptions |
| *nextOptions* | Table of key-value strings| Yes | An *options* table that can be directly used as an argument for subsequent paginated *list()* call; it contains the *pageToken* returned by the currently executed *list()* call. *nextOptions* is `null` if no more results are available, *paginate* was `false`, or the operation failed |

### *GooglePubSub.Subscriptions.iam()*

Returns an instance of *GooglePubSub.IAM* class that can be used for execution of Identity and Access Management methods for subscriptions.

### *GooglePubSub.Subscriptions.getImpAgentEndpoint(relativePath = null, secretToken = null)*

Composes an endpoint URL based on the URL of the IMP agent where the library is running.

The result URL can be used to create a push subscription and receive messages from this subscription using *GooglePubSub.PushSubscriber* class.

Parameters:
- *relativePath* - *string* - optional - relative path which to be added to the IMP agent URL
- *secretToken* - *string* - optional - secret token specified by a user. It allows to verify that the messages pushed to the push endpoint are originated from the Google Cloud Pub/Sub service. More information see [here](https://cloud.google.com/pubsub/docs/faq#security)

Returns:
- *string* - the result URL

## Class *GooglePubSub.PullSubscriber*

Allows to receive messages from a pull subscription of Google Cloud Pub/Sub service and acknowledge the received messages.

### Constructor *GooglePubSub.PullSubscriber(projectId, oAuthTokenProvider, subscrName)*

Parameters:
- *projectId* - *string* - Google Cloud Project ID
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](/README.md#access-token-provider)
- *subscrName* - *string* - name of the subscription to receive messages from

Returns:
- *GooglePubSub.PullSubscriber* instance

### *GooglePubSub.PullSubscriber.pull(options = null, callback = null)*

One shot pulling.
Checks for new messages and calls a callback immediately, with or without the messages.

The new messages (if any) are returned in the callback (not more than *maxMessages*).
The messages are automatically acknowledged if *autoAck* option is set to *true*.
The callback is called in any case, even if there are no new messages.

Only one from all pull operations can be active at a time. An attempt to call a new pull operation while another one is active fails with *PUB_SUB_ERROR.LIBRARY_ERROR* error.

Parameters:
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *autoAck* - *boolean* - automatically acknowledge the message once it's pulled. Default: *false*
  - *maxMessages* - *integer* - the maximum number of messages returned. The Google Pub/Sub service may return fewer than the number specified even if there are more messages available. Default: 20
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, messages)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *messages* - *array* of *GooglePubSub.Message* - messages returned

### *GooglePubSub.PullSubscriber.periodicPull(period, options = null, callback = null)*

Periodic pulling.
Periodically checks for new messages and calls a callback if new messages are available at a time of a check.

The new messages are returned in the callback (not more than *maxMessages*).
The messages are automatically acknowledged if *autoAck* option is set to *true*.
The callback is not called when there are no new messages at a time of a check.

Only one from all pull operations can be active at a time. An attempt to call a new pull operation while another one is active fails with *PUB_SUB_ERROR.LIBRARY_ERROR* error.

Parameters:
- *period* - *float* - period of checks, in seconds, must be positive float value. The specified period should not be too small, otherwise a number of http requests per second will exceed Electric Imp maximum rate limit and further requests will fail with *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error. More information about http requests rate limiting is [here](https://electricimp.com/docs/api/httprequest/)
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *autoAck* - *boolean* - automatically acknowledge the message once it's pulled. Default: *false*
  - *maxMessages* - *integer* - the maximum number of messages returned. The Google Pub/Sub service may return fewer than the number specified even if there are more messages available. Default: 20
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, messages)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *messages* - *array* of *GooglePubSub.Message* - messages returned

### *GooglePubSub.PullSubscriber.pendingPull(options = null, callback = null)*

Pending (waiting) pulling.
Waits for new messages and calls a callback when new messages appear.

The new messages are returned in the callback (not more than *maxMessages*).
The messages are automatically acknowledged if *autoAck* option is set to *true*.
The callback is called only when new messages are available (or in case of an error).

Only one from all pull operations can be active at a time. An attempt to call a new pull operation while another one is active fails with *PUB_SUB_ERROR.LIBRARY_ERROR* error.

Parameters:
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *repeat* - *boolean* - if *true*, a new *GooglePubSub.PullSubscriber.pendingPull()* method with the same parameters is automatically called by the library after the callback is executed. Default: *false*
  - *autoAck* - *boolean* - automatically acknowledge the message once it's pulled. Default: *false*
  - *maxMessages* - *integer* - the maximum number of messages returned. The Google Pub/Sub service may return fewer than the number specified even if there are more messages available. Default: 20
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, messages)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *messages* - *array* of *GooglePubSub.Message* - messages returned

### *GooglePubSub.PullSubscriber.stopPull()*

Stops periodic or pending pull operation if it was started by *GooglePubSub.PullSubscriber.periodicPull()* or *GooglePubSub.PullSubscriber.pendingPull()* methods earlier.
Does nothing if no periodic or pending pull operation is active at this moment.

Returns nothing.

### *GooglePubSub.PullSubscriber.ack(message, callback = null)*

Acknowledges to the Google Pub/Sub service that the message(s) has been received.

Acknowledging a message whose ack deadline has expired may succeed, but such a message may be redelivered by the Google Pub/Sub service later.
Acknowledging a message more than once will not result in an error.

Parameters:
- *message* - different types - the message(s) to be acknowledged. It can be:
  - *string* - acknowledgment ID of the received message
  - *array* of *strings* - array of the acknowledgment IDs
  - *GooglePubSub.Message* - the received *GooglePubSub.Message* instance
  - *array* of *GooglePubSub.Message* - array of the received *GooglePubSub.Message* instances
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

### *GooglePubSub.PullSubscriber.modifyAckDeadline(message, ackDeadlineSeconds, callback = null)*

Modifies the ack deadline for a specific message(s).

This method is useful to indicate that more time is needed to process a message by the subscriber, or to make the message available for redelivery if the processing was interrupted.

Parameters:
- *message* - different types - the message(s) whose ack deadline to be modified. It can be:
  - *string* - acknowledgment ID of the received message
  - *array* of *strings* - array of the acknowledgment IDs
  - *GooglePubSub.Message* - the received *GooglePubSub.Message* instance
  - *array* of *GooglePubSub.Message* - array of the received *GooglePubSub.Message* instances
- *ackDeadlineSeconds* - *integer* - the new ack deadline, in seconds
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

## Class *GooglePubSub.PushSubscriber*

Allows to receive messages from a push subscription of Google Cloud Pub/Sub service configured with a push endpoint which is based on URL of the IMP agent where the library is running. The messages are automatically acknowledged by the library.

### Constructor *GooglePubSub.PushSubscriber(projectId, oAuthTokenProvider, subscrName)*

Parameters:
- *projectId* - *string* - Google Cloud Project ID
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](/README.md#access-token-provider)
- *subscrName* - *string* - name of the subscription to receive messages from

Returns:
- *GooglePubSub.PushSubscriber* instance

### *GooglePubSub.PushSubscriber.setMessagesHandler(messagesHandler, callback = null)*

Checks if the subscription is configured by appropriate push endpoint URL (based on URL of the IMP agent where the library is running) and sets the specified handler function to be executed every time new messages are received from the Google Pub/Sub service.

If the subscription is not configured by an appropriate URL, the operation fails with *PUB_SUB_ERROR.LIBRARY_ERROR* error.

Parameters:
- *messagesHandler* - *function* - the handler function to be executed when new messages are received
- *callback* - *function* - optional - callback function to be executed once the operation is completed

The handler function signature: **messagesHandler(error, messages)**, where:
- *error* - *GooglePubSub.Error* - error details - in case when the received messages have incorrect format then  *PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE* error is reported; *null* if the received messages are correct
- *messages* - *array* of *GooglePubSub.Message* - messages received

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

## Class *GooglePubSub.IAM.Policy*

Represents Google Identity and Access Management (IAM) policy.

Public fields:
- *version* - *integer* - version of the policy
- *bindings* - *array* of *tables* { "role" : *string*, "members" : *array* of *strings* } - array of bindings. Every binding binds a list of members to a role, where the "members" can be user accounts, Google groups, Google domains, service accounts; the "role" is a named set of permissions defined by IAM. For a list of the supported roles see [Google Cloud Pub/Sub Access Control documentation](https://cloud.google.com/pubsub/docs/access_control).
- *etag* - *string* - entity tag. See [here](https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy).

### Constructor *GooglePubSub.IAM.Policy(version = 0, bindings = null, etag = null)*

Parameters:
- *version* - *integer* - optional - version of the policy. Default: 0
- *bindings* - *array* of *tables* { "role" : *string*, "members" : *array* of *strings* } - optional - array of bindings (see the description of *bindings* public field)
- *etag* - *string* - optional - entity tag. See [here](https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy).

Returns:
- *GooglePubSub.IAM.Policy* instance that can be passed as an argument to *GooglePubSub.IAM.setPolicy()* method to set a resource policy.

## Class *GooglePubSub.IAM*

Provides Google Identity and Access Management (IAM) functionality for individual Google Pub/Sub resources (topics and subscriptions).

IAM and its features are described in details in the [Google Cloud Identity and Access Management overview](https://cloud.google.com/iam/docs/overview)

### *GooglePubSub.IAM.getPolicy(resourceName, callback = null)*

Gets the access control policy for the specified resource (topic or subscription).

Parameters:
- *resourceName* - *string* - name of the topic or subscription
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, policy)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *policy* - *GooglePubSub.IAM.Policy* - IAM policy obtained for the resource.

### *GooglePubSub.IAM.setPolicy(resourceName, policy, callback = null)*

Sets the access control policy on the specified resource (topic or subscription).
Replaces the previous policy, if it existed for the resource.

Parameters:
- *resourceName* - *string* - name of the topic or subscription
- *policy* - *GooglePubSub.IAM.Policy* - IAM policy to be set
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, policy)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *policy* - *GooglePubSub.IAM.Policy* - new IAM policy of the resource

### *GooglePubSub.IAM.testPermissions(resourceName, permissions, callback = null)*

Tests the set of permissions for the specified resource (topic or subscription).

If the resource does not exist, this operation returns an empty set of permissions, not *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error.

Parameters:
- *resourceName* - *string* - name of the topic or subscription
- *permissions* - *string* or *array* of *strings* - the permission(s) to test for the resource. Permissions with wildcards such as \* or pubsub.topics.\* are not allowed. For a list of the available permissions see [Google Cloud Pub/Sub Access Control documentation](https://cloud.google.com/pubsub/docs/access_control)
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, permissions)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *permissions* - *array* of *strings* - a subset of the permissions that is allowed for the resource.
