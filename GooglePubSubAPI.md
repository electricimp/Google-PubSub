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

Deletes the specified topic, if it exists. If it doesn’t, the operation fails with a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

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

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *topicNames* | Array of strings | The names of the topics |
| *nextOptions* | Table of key-value strings | An *options* table that can be directly used as an argument for a subsequent paginated *list()* call; it contains *pageToken* returned by the currently executed *list()* call. *nextOptions* is `null` if no more results are available, the *paginate* option was `false` or the operation fails |

### iam()

Returns an instance of the GooglePubSub.IAM class that can be used to execute Identity and Access Management methods for topics.

## GooglePubSub.Publisher

Allows your code to publish messages to a specific topic.

### Constructor: GooglePubSub.Publisher(*projectId, oAuthTokenProvider, topicName*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes  | The project’s ID |
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

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *messageIds* | Array of strings | Google Pub/Sub service IDs of each published message, in the same order as the messages in the request. IDs are guaranteed to be unique within the topic |

## GooglePubSub.SubscriptionConfig

Represents a Google Pub/Sub subscription’s configuration and has the following public properties:

- *topicName* &mdash; The name of the Google Pub/Sub topic from which this subscription receives messages, as a string.
- *ackDeadlineSeconds* &mdash; An integer holding the maximum time (in seconds) after receiving a message when the message must be acknowledged before it is redelivered by the Pub/Sub service.
- *pushConfig* &mdash; An instance of GooglePubSub.PushConfig which holds additional configuration for push subscription, or `null` for pull subscriptions.

### Constructor: GooglePubSub.SubscriptionConfig(*topicName, ackDeadlineSeconds, pushConfig*)

Creates a subscription configuration that can be used to crete a new subscription.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *topicName* | String | Yes | The name of the topic from which this subscription receives messages |
| *ackDeadlineSeconds* | Integer | Optional | The maximum time (in seconds) after receiving a message when the message must be acknowledged before it is redelivered by the Pub/Sub service. Default: 10 seconds |
| *pushConfig* | GooglePubSub.PushConfig | Optional | Additional configuration for push subscription. Default: `null` (ie. pull subscription) |

## GooglePubSub.PushConfig

Represents the additional configuration details required by a push subscription. It has the following public properties:

- *pushEndpoint* &mdash; A string containing the URL of the endpoint that messages should be pushed to.
- *attributes* &mdash; A table of key-value strings holding [push endpoint attributes](https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.subscriptions#PushConfig). May be `null`.

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
| *projectId* | String | Yes  | The project’s ID |
| *oAuthTokenProvider* | Object | Yes | The provider of access tokens suitable for Google Pub/Sub service requests authentication. See [here](/README.md#access-token-provider) for more information |

### obtain(*subscriptionName[, options][, callback]*)

Obtains the specified subscription. If a subscription with the specified name exists, the method retrieves its configuration. If  a subscription with the specified name doesn’t exist, and the *autoCreate* option is `true`, the subscription is created. In this case, the *subscrConfig* option must be specified. If the subscription does not exist and *autoCreate* is `false`, the method fails with a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *subscriptionName* | String | Yes | The unique name of the subscription |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*autoCreate* &mdash; a boolean indicating whether the subscription should be created if it does not exist. Default: `false`<br>*subscrConfig* &mdash; a GooglePubSub.SubscriptionConfig instance holding configuration of the subscription to be created. If *autoCreate* is `true`, *subscrConfig* must be specified. Otherwise, *subscrConfig* is ignored |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *subscrConfig* | GooglePubSub.SubscriptionConfig | The configuration of the obtained subscription |

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
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*topicName* &mdash; A string with name of the topic to list subscriptions from. If not specified, the method lists all subscriptions registered to the project.<br>*paginate* &mdash; a boolean indicating whether the operation returns a limited number of topics (up to *pageSize*) and a new *pageToken* which allows to obtain the next page of data, or the entire list of topics (`false`). Default: `false`.<br>*pageSize* &mdash; An integer specifying the maximum number of topics to return. If *paginate* is `false`, this option is ignored. Default: 20.<br>*pageToken* &mdash; A string containing the page token returned by the previous paginated *list()* call; indicates that the library should return the next page of data. If *paginate* is `false`, this option is ignored. If *paginate* is `true` and *pageToken* is not specified, the library starts listing from the beginning |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *subscrNames* | Array of strings | The names of the subscriptions |
| *nextOptions* | Table of key-value strings| An *options* table that can be directly used as an argument for subsequent paginated *list()* call; it contains the *pageToken* returned by the currently executed *list()* call. *nextOptions* is `null` if no more results are available, *paginate* was `false`, or the operation failed |

### *iam()*

Returns an instance of the GooglePubSub.IAM class that can be used to execute Identity and Access Management methods for subscriptions.

### getImpAgentEndpoint(*[relativePath][, secretToken]*)

Composes and returns an endpoint URL based on the URL of the agent where the library is running. The resulting URL can be used to create a push subscription and receive messages from this subscription using the GooglePubSub.PushSubscriber class.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *relativePath* | String | Optional | The relative path which to be added to the agent URL |
| *secretToken* | String | Optional | A secret token specified by a user. It can be used to verify that the messages pushed to the push endpoint are originated from the Google Cloud Pub/Sub service. More information [here](https://cloud.google.com/pubsub/docs/faq#security) |

## GooglePubSub.PullSubscriber

Allows messages to be received from a pull subscription and then acknowledged.

### Constructor: GooglePubSub.PullSubscriber(*projectId, oAuthTokenProvider, subscriptionName*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes  | The project’s ID |
| *oAuthTokenProvider* | Object | Yes | The provider of access tokens suitable for Google Pub/Sub service requests authentication. See [here](/README.md#access-token-provider) for more information |
| *subscriptionName* | String | Yes | The unique name of the subscription |

### pull(*[options][, callback]*)

Provides one-shot pulling. Checks for new messages and calls any callback immediately, with or without the messages. The new messages (if any) are returned in the callback (up to *maxMessages* in number). The messages are automatically acknowledged if the *autoAck* option is `true`.

Only one pull operation can be active at a time. An attempt to call a new pull operation while another one is active fails with a *PUB_SUB_ERROR.LIBRARY_ERROR* error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*autoAck* &mdash; A boolean indicating whether messages should be automatically acknowledged once it's pulled. Default: `false`<br>*maxMessages* &mdash; An integer specifying the maximum number of messages to be returned. The Google Pub/Sub service may return fewer than the number specified even if there are more messages available. Default: 20 |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *messages* | Array of GooglePubSub.Message instances | The messages returned |

### periodicPull(*period[, options][, callback]*)

Provides periodic pulling. It periodically checks for new messages and calls any callback if new messages are available at the  time of the check. The new messages are returned in the callback (up to *maxMessages* in number). The messages are automatically acknowledged if the *autoAck* option is `true`.

Only one pull operation can be active at a time. An attempt to call a new pull operation while another one is active fails with a *PUB_SUB_ERROR.LIBRARY_ERROR* error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *period* | Float | Yes | The period of checks, in seconds. Must be positive. The specified period should not be too small, otherwise a number of HTTP requests per second will exceed Electric Imp’s maximum rate limit and further requests will fail with a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error. More information about HTTP request rate-limiting can be found  [here](https://electricimp.com/docs/api/httprequest/) |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*autoAck* &mdash; A boolean indicating whether messages should be automatically acknowledged once it's pulled. Default: `false`<br>*maxMessages* &mdash; An integer specifying the maximum number of messages to be returned. The Google Pub/Sub service may return fewer than the number specified even if there are more messages available. Default: 20 |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *messages* | Array of GooglePubSub.Message instances | The messages returned |

### pendingPull(*[options][, callback]*)

Provides pending (waiting) pulling. It waits for new messages and calls any callback when new messages appear. The new messages are returned in the callback (up to *maxMessages* in number). The messages are automatically acknowledged if the *autoAck* option is `true`.

Only one pull operation can be active at a time. An attempt to call a new pull operation while another one is active fails with a *PUB_SUB_ERROR.LIBRARY_ERROR* error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table of key-value strings | Optional | The valid keys (options) are:<br>*repeat* &mdash; A boolean: if `true`, *pendingPull()* is automatically called with the same parameters after the callback is executed. Default: `false`<br>*autoAck* &mdash; A boolean indicating whether messages should be automatically acknowledged once it's pulled. Default: `false`<br>*maxMessages* &mdash; An integer specifying the maximum number of messages to be returned. The Google Pub/Sub service may return fewer than the number specified even if there are more messages available. Default: 20 |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *messages* | Array of GooglePubSub.Message instances | The messages returned |

### stopPull()

Stops periodic or pending pull operation if it was started by *periodicPull()* or *pendingPull()*. It does nothing if no periodic or pending pull operation is currently active.

### ack(*message[, callback]*)

Acknowledges that the message or messages have been received. Acknowledging a message whose acknowledgement deadline has expired may succeed, but such a message may be redelivered by the Google Pub/Sub service later. Acknowledging a message more than once will not result in an error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *message* | Various types | Yes | The message(s) to be acknowledged. It can be:
  - String &mdash; The acknowledgment ID of the received message
  - Array of strings &mdash; An array of the acknowledgment IDs
  - GooglePubSub.Message &mdash; the received GooglePubSub.Message instance
  - Array of GooglePubSub.Message instances |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

### modifyAckDeadline(*message, ackDeadlineSeconds[, callback =]*)

Modifies the acknowledgement deadline for a specific message or messages. This method is useful to indicate that more time is needed to process a message by the subscriber, or to make the message available for redelivery if the processing was interrupted.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *message* | Various types | Yes | The message(s) to be acknowledged. It can be:
  - String &mdash; The acknowledgment ID of the received message
  - Array of strings &mdash; An array of the acknowledgment IDs
  - GooglePubSub.Message &mdash; the received GooglePubSub.Message instance
  - Array of GooglePubSub.Message instances |
| *ackDeadlineSeconds* | Integer | Yes | The new acknowledgement deadline, in seconds |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

## GooglePubSub.PushSubscriber

Allows your code to receive messages from a push subscription. The messages are automatically acknowledged by the library.

### Constructor: GooglePubSub.PushSubscriber(*projectId, oAuthTokenProvider, subscriptionName*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes  | The project’s ID |
| *oAuthTokenProvider* | Object | Yes | The provider of access tokens suitable for Google Pub/Sub service requests authentication. See [here](/README.md#access-token-provider) for more information |
| *subscriptionName* | String | Yes | The unique name of the subscription |

### setMessagesHandler(*messagesHandler[, callback]*)

Checks if the subscription is configured with an appropriate push endpoint URL (based on URL of the agent where the library is running) and sets the specified handler function to be executed every time new messages are received from the Google Pub/Sub service.

If the subscription is not configured with an appropriate URL, the operation fails with a *PUB_SUB_ERROR.LIBRARY_ERROR* error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *messagesHandler* | Function | Yes | The function to be executed when new messages are received |
| *callback* | Function | Optional | Executed once the operation is completed |

The *messagesHandler* function has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details. When the received messages have an incorrect format, *PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE* error is reported, otherwise `null` if the received messages are correctly formatted |
| *messages* | An array GooglePubSub.Message instances | The messages that have been received |

The method returns nothing. The result of the operation may be obtained via the callback function, which has a single parameter, *error*, which will be `null` on success, or an instance of GooglePubSub.Error.

## GooglePubSub.IAM.Policy

Represents a Google Identity and Access Management (IAM) policy and has the following public properties:

- *version* &mdash; An integer indicating the version of the policy.
- *bindings* &mdash; An array of tables each with the keys *role* (string) and *members* (array of strings) which detail the bindings. Every binding binds a list of members to a role, where the members can be user accounts, Google groups, Google domains, or service accounts. Each role is a named set of permissions defined by IAM. For a list of the supported roles see the [Google Cloud Pub/Sub Access Control documentation](https://cloud.google.com/pubsub/docs/access_control).
- *etag* &mdash; A string containing the [entity tag](https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy).

### Constructor: GooglePubSub.IAM.Policy(*[version][, bindings][, etag]*)

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *version* | Integer | Optional | The version of the policy. Default: 0 |
| *bindings* | Array of tables | Optional | The bindings *(see above)* |
| *etag* | String | Optional | An entity tag. See [here](https://cloud.google.com/pubsub/docs/reference/rest/v1/Policy) for more information |

## GooglePubSub.IAM

Provides Google Identity and Access Management (IAM) functionality for individual Google Pub/Sub resources (topics and subscriptions).

IAM and its features are described in details in the [Google Cloud Identity and Access Management Overview](https://cloud.google.com/iam/docs/overview)

### getPolicy(*resourceName[, callback]*)

Gets the access control policy for the specified resource (topic or subscription).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *resourceName* | String | Yes | The name of the required topic or subscription |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *policy* | GooglePubSub.IAM.Policy | IAM policy obtained for the resource |

### setPolicy(*resourceName, policy[, callback]*)

Sets the access control policy on the specified resource (topic or subscription). It replaces any previous policy.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *resourceName* | String | Yes | The name of the required topic or subscription |
| *policy* | GooglePubSub.IAM.Policy | Yes | The IAM policy to be applied |
| *callback* | Function | Optional | Executed once the operation is completed |

The method returns nothing. The result of the operation may be obtained via the callback function, which has the following parameters:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *policy* | GooglePubSub.IAM.Policy | The new IAM policy for the resource |

### testPermissions(*resourceName, permissions[, callback]*)

Tests the set of permissions for the specified resource (topic or subscription). If the resource does not exist, this operation returns an empty set of permissions, rather than a *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *resourceName* | String | Yes | The name of the required topic or subscription |
| *permissions* | String or array of string | Yes | The permission(s) to test. Permissions with wildcards such as \* or pubsub.topics.\* are not allowed. For a list of the available permissions see the [Google Cloud Pub/Sub Access Control documentation](https://cloud.google.com/pubsub/docs/access_control) |
| *callback* | Function | Optional | Executed once the operation is completed |


Parameters:
- *resourceName* - *string* - name of the topic or subscription
- *permissions* - *string* or *array* of *strings* -
- *callback* - *function* - optional - callback function to be executed once the operation is completed

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | GooglePubSub.Error | Error details, or `null` if the operation succeeds |
| *permissions* | Array of strings | A subset of the permissions set for the resource |
