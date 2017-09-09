# Google PubSub Library API

## Class *GooglePubSub*

### *GooglePubSub.setDebug(value)*

Enables/disables the library debug output (including errors logging). Disabled by default.

Parameters:
- *value* - *boolean* - *true* to enable / *false* to disable debug output

Returns nothing.

## Class *GooglePubSub.Error*

Represents an error returned by the library.

Public fields:
- *type* - *PUB_SUB_ERROR* - error type, one of the *PUB_SUB_ERROR* enum values:
  - *PUB_SUB_ERROR.LIBRARY_ERROR* - the library is wrongly initialized, or a method is called with invalid argument(s), or an internal error. The error details can be found in the *details* field.
  - *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* - HTTP request to Google Cloud Pub/Sub service fails. The error details can be found in the *details*, *httpStatus* and *httpResponse* fields.
  - *PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE* - unexpected response from Google Pub/Sub service. The error details can be found in the *details* and *httpResponse* fields.
- *details* - *string* - error details
- *httpStatus* - *integer* - HTTP status code, *null* if *type* is *PUB_SUB_ERROR.LIBRARY_ERROR*
- *httpResponse* - *table* of key-value *strings* - response body of the failed request, *null* if *type* is *PUB_SUB_ERROR.LIBRARY_ERROR*

## Class *GooglePubSub.Message*

Represents Google Pub/Sub Message: a combination of any format data and optional attributes that a publisher sends to a topic and subscriber(s) receive.

Public fields:
- *id* - *string* - ID of the message
- *ackId* - *string* - ID used to acknowledge the message receiving
- *data* - any type - the message data
- *attributes* - *table* of key-value *strings* - optional attributes of the message
- *publishTime* - *string* - the time when the message was published to the Google Cloud Pub/Sub service. Format is RFC3339 UTC "Zulu", accurate to nanoseconds, e.g. "2014-10-02T15:01:23.045123456Z"

### Constructor *GooglePubSub.Message(data = null, attributes = null)*

Creates a message that can be used for message publishing.
The message must contain either a non-empty data field, or at least one attribute. Otherwise *GooglePubSub.Publisher.publish()* method will fail with *PUB_SUB_ERROR.LIBRARY_ERROR* error.

Parameters:
- *data* - any type - optional - the message data
- *attributes* - *table* of key-value *strings* - optional - the message attributes

Returns:
- *GooglePubSub.Message* instance that can be sent to Google Pub/Sub service using *GooglePubSub.Publisher.publish()* method.

## Class *GooglePubSub.Topics*

Provides access to Google Pub/Sub Topics manipulation methods.

### Constructor *GooglePubSub.Topics(projectId, oAuthTokenProvider)*

Parameters:
- *projectId* - *string* - Google Cloud Project ID
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](#access-token-provider)

Returns:
- *GooglePubSub.Topics* instance

### *GooglePubSub.Topics.obtain(topicName, options = null, callback = null)*

Checks if the specified topic exists and optionally creates it if not.
If the topic does not exist and *autoCreate* option is *true*, the topic is created.
If the topic does not exist and *autoCreate* option is *false*, the method fails with *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

Parameters:
- *topicName* - *string* - name of the topic.
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *autoCreate* - *boolean* - create the topic if it does not exist. Default: *false*
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

### *GooglePubSub.Topics.remove(topicName, callback = null)*

Deletes the specified topic, if it exists.
Otherwise - fails with *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

Existing subscriptions related to the deleted topic are not destroyed.

After the topic is deleted, a new topic may be created with the same name; this will be an entirely new topic with none of the old configuration or subscriptions.

Parameters:
- *topicName* - *string* - name of the topic.
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

### *GooglePubSub.Topics.list(options = null, callback = null)*

Get a list of the topics (names of all topics) registered to the project.

Parameters:
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *paginate* - *boolean* - if *true*, the operation returns limited number of topics (up to *pageSize*) and a new *pageToken* which allows to obtain the next page of data. If *false*, the operation returns the entire list of topics. Default: *false*
  - *pageSize* - *integer* - maximum number of topics to return. If *paginate* option value is *false*, this option is ignored. Default: 20
  - *pageToken* - *string* - page token returned by the previous paginated *GooglePubSub.Topics.list()* call; indicates that the library should return the next page of data. If *paginate* option value is *false*, this option is ignored. If *paginate* option value is *true* and *pageToken* option is not specified, the library starts listing from the beginning.
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, topicNames, nextOptions = null)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *topicNames* - *array* of *strings* - names of the topics
- *nextOptions* - *table* of key-value *strings* - value of the *options* table that can be directly used as an argument for subsequent paginated *GooglePubSub.Topics.list()* call; it contains *pageToken* returned by the currently executed *GooglePubSub.Topics.list()* call. *nextOptions* is null in one of the following cases:
  - no more results are available
  - *paginate* option value was *false*
  - the operation fails

### *GooglePubSub.Topics.iam()*

Returns an instance of *GooglePubSub.IAM* class that can be used for execution of Identity and Access Management methods for topics.

## Class *GooglePubSub.Publisher*

Allows to publish messages to a specific topic of Google Cloud Pub/Sub service.

### Constructor *GooglePubSub.Publisher(projectId, oAuthTokenProvider, topicName)*

Parameters:
- *projectId* - *string* - Google Cloud Project ID
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](#access-token-provider)
- *topicName* - *string* - name of the topic to publish message to

Returns:
- *GooglePubSub.Publisher* instance

### *GooglePubSub.Publisher.publish(message, callback = null)*

Publishes the provided message or array of messages to the topic.

Parameters:
- *message* - different types - the message(s) to be published. It can be:
  - any type - raw data value
  - *array* of any type - array of raw data values
  - *GooglePubSub.Message* - pre-created instance of *Message*
  - *array* of *GooglePubSub.Message* - array of pre-created instances of *Message*
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, messageIds)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *messageIds* - *array* of *strings* - Google Pub/Sub service assigned ID of each published message, in the same order as the messages in the request. IDs are guaranteed to be unique within the topic.

## Class *GooglePubSub.SubscriptionConfig*

Represents configuration of a Google Pub/Sub Subscription.

Public fields:
- *topicName* - *string* - name of the Google Pub/Sub topic from which this subscription receives messages
- *ackDeadlineSeconds* - *integer* - the maximum time (in seconds) after receiving a message when the message must be acknowledged before it is redelivered by Pub/Sub service
- *pushConfig* - *GooglePubSub.PushConfig* - additional configuration for push subscription; *null* for pull subscription

### Constructor *GooglePubSub.SubscriptionConfig(topicName, ackDeadlineSeconds, pushConfig = null)*

Creates a subscription configuration that can be used for the subscription creation in Google Pub/Sub service.

Parameters:
- *topicName* - *string* - name of the Google Pub/Sub topic from which this subscription receives messages
- *ackDeadlineSeconds* - *integer* - optional - the maximum time (in seconds) after receiving a message when the message must be acknowledged before it is redelivered by Pub/Sub service. Default : 10 seconds
- *pushConfig* - *GooglePubSub.PushConfig* - optional - additional configuration for push subscription. Default: *null* (pull subscription)

Returns:
- *GooglePubSub.SubscriptionConfig* instance that can be passed into *GooglePubSub.Subscriptions.obtain()* method to create the subscription.

## Class *GooglePubSub.PushConfig*

Represents additional configuration of a push subscription.

Public fields:
- *pushEndpoint* - *string* - push endpoint URL (URL of a endpoint that messages should be pushed to)
- *attributes* - *table* of key-value *strings* - [push endpoint attributes](https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.subscriptions#PushConfig). May be *null*

### Constructor *GooglePubSub.PushConfig(pushEndpoint, attributes = null)*

Parameters:
- *pushEndpoint* - *string* - push endpoint URL (URL of a endpoint that messages should be pushed to)
- *attributes* - *table* of key-value *strings* - optional - [push endpoint attributes](https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.subscriptions#PushConfig)

Returns:
- *GooglePubSub.PushConfig* instance that can be passed into *GooglePubSub.Subscriptions.obtain()* method to create the push subscription.

## Class *GooglePubSub.Subscriptions*

Provides access to Google Pub/Sub Subscriptions manipulation methods.

### Constructor *GooglePubSub.Subscriptions(projectId, oAuthTokenProvider)*

Parameters:
- *projectId* - *string* - Google Cloud Project ID
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](#access-token-provider)

Returns:
- *GooglePubSub.Subscriptions* instance

### *GooglePubSub.Subscriptions.obtain(subscrName, options = null, callback = null)*

Obtains (get or create) the specified subscription.

If subscription with the specified name exists, the method retrieves it's configuration. 

If subscription with the specified name does not exist and *autoCreate* option is *true*, the subscription is created. In this case *subscrConfig* option must be specified.

If the subscription does not exist and *autoCreat*e option is *false*, the method fails with *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

Parameters:
- *subscrName* - *string* - name of the subscription
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *autoCreate* - *boolean* - create the subscription if it does not exist. Default: *false*
  - *subscrConfig* - *GooglePubSub.SubscriptionConfig* - optional - configuration of the subscription to be created. If *autoCreate* option is *true*, *subscrConfig* option must be specified. Otherwise, *subscrConfig* option is ignored.
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, subscrConfig)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *subscrConfig* - *GooglePubSub.SubscriptionConfig* - configuration of the obtained subscription

### *GooglePubSub.Subscriptions.modifyPushConfig(subscrName, pushConfig, callback = null)*

Modifies push configuration for the specified subscription.
The method may be used to change a push subscription to a pull one or vice versa, or change push endpoint URL and other attributes of a push subscription.

To modify a push subscription to a pull one, pass *nul*l or empty table as *pushConfig* parameter value.

Parameters:
- *subscrName* - *string* - name of the subscription
- *pushConfig* - *GooglePubSub.PushConfig* - new push configuration for future deliveries. *null* or empty *pushConfig* indicates that the Pub/Sub service should stop pushing messages from the given subscription and allow messages to be pulled and acknowledged.
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

### *GooglePubSub.Subscriptions.remove(subscrName, callback = null)*

Deletes the specified subscription, if it exists.
Otherwise - fails with *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* error (with *httpStatus* 404).

All messages retained in the subscription are immediately dropped and cannot be delivered neither by pull, nor by push ways.

After the subscription is deleted, a new one may be created with the same name; but the new one has no association with the old subscription or its topic unless the same topic is specified for the new subscription.

Parameters:
- *subscrName* - *string* - name of the subscription
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds

### *GooglePubSub.Subscriptions.list(options = null, callback = null)*

Gets a list of the subscriptions (names of all subscriptions) registered to the project or related to the specified topic.

Parameters:
- *options* - *table* of key-value *strings* - optional - method options. The valid keys are:
  - *topicName* - *string* - name of the topic to list subscriptions from. If specified, the method lists the subscriptions related to this topic. If not specified, the method lists all subscriptions registered to the project.
  - *paginate* - *boolean* - if *true*, the operation returns limited number of subscriptions (up to *pageSize*) and a new *pageToken* which allows to obtain the next page of data. If *false*, the operation returns the entire list of subscriptions. Default: *false*
  - *pageSize* - *integer* - maximum number of subscriptions to return. If *paginate* option value is *false*, this option is ignored. Default: 20
  - *pageToken* - *string* - page token returned by the previous paginated *GooglePubSub.Subscriptions.list()* call; indicates that the library should return the next page of data. If *paginate* option value is *false*, this option is ignored. If *paginate* option value is *true* and *pageToken* option is not specified, the library starts listing from the beginning.
- *callback* - *function* - optional - callback function to be executed once the operation is completed

Returns nothing. A result of the operation may be obtained via the callback function.

The callback function signature: **callback(error, subscrNames, nextOptions = null)**, where:
- *error* - *GooglePubSub.Error* - error details, *null* if the operation succeeds
- *subscrNames* - *array* of *strings* - names of the subscriptions
- *nextOptions* - *table* of key-value *strings* - value of the *options* table that can be directly used as an argument for subsequent paginated *GooglePubSub.Subscriptions.list()* call; it contains *pageToken* returned by the currently executed *GooglePubSub.Subscriptions.list()* call. *nextOptions* is null in one of the following cases:
  - no more results are available
  - *paginate* option value was *false*
  - the operation fails

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
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](#access-token-provider)
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
- *oAuthTokenProvider* - *object* - provider of access tokens suitable for Google Pub/Sub service requests authentication, [see here](#access-token-provider)
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



