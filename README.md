# GooglePubSub

The library lets your IMP agent code to connect to [Google Cloud Pub/Sub service](https://cloud.google.com/pubsub). It makes use of the [Google Cloud Pub/Sub REST API](https://cloud.google.com/pubsub/docs/reference/rest).

**To add this library to your project, add** `#require "GooglePubSub.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## Google Cloud Pub/Sub Service

Google Cloud Pub/Sub is a publish/subscribe (Pub/Sub) service - a messaging service where the senders of messages are decoupled from the receivers of messages. There are several key concepts in the Pub/Sub service:
- Message: the data (with optional attributes) that moves through the service.
- Topic: a named entity that represents a feed of messages.
- Subscription: a named entity that represents an interest in receiving messages on a particular topic.
- Publisher: creates messages and sends (publishes) them to the messaging service on a specified topic.
- Subscriber: receives messages on a specified subscription.

Communication between publishers and subscribers can be one-to-many, many-to-one and many-to-many.

For more information see [Google Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs/overview)

Before working with Google Cloud Pub/Sub Service you need to:
- register Google Cloud Platform account,
- create and configure [Google Cloud Project](#google-cloud-project).

### Google Cloud Project

Google Cloud Project is a basic entity of Google Cloud Platform which allows users to create, configure and use all Cloud Platform resources and services, including Pub/Sub.
All Pub/Sub Topics and Subscriptions are owned by a specific Project.
To manage Pub/Sub resources associated with different Projects, you may use different instances of the classes from this library.

For more information see [Google Cloud Project description](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects) and [Creating and Managing Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

An example of how to create and configure a Google Cloud project see [here](./Examples/README.md#google-cloud-account-configuration).

## Library Usage

The library API is described in details in the source file, [here](./GooglePubSub.agent.lib.nut).

### Main Components

The library consists of five independent main components (classes). You can instantiate and use any of these components in your IMP agent code depending on your application requirements.

- [GooglePubSub.Topics class](#topics-class): provides access to Pub/Sub Topics management methods. One instance of this class is enough to manage all topics of one Project.

- [GooglePubSub.Subscriptions class](#subscriptions-class): provides access to Pub/Sub Subscriptions management methods. One instance of this class is enough to manage all subscriptions of one Project.

- [GooglePubSub.Publisher class](#publisher-class): allows an imp to publish messages to a topic. One instance of this class allows an imp to publish messages to one topic.

- [GooglePubSub.PullSubscriber class](#pullsubscriber-class): allows an imp to receive messages from a pull subscription. One instance of this class allows an imp to receive messages from one pull subscription.

- [GooglePubSub.PushSubscriber class](#pushsubscriber-class): allows an imp to receive messages from a push subscription configured with that imp's agent URL as a push endpoint. One instance of this class allows an imp to receive messages from one push subscription.
 
### Instantiation

To instantiate any [main component](#main-components) of this library you need to have:

- [Google Cloud Project ID](#google-cloud-project)

- [Provider of access tokens](#access-tokens-provider) suitable for Google Cloud Pub/Sub service requests authentication.

#### Access Token Provider

Information about Google Cloud Pub/Sub service authentication see [here](https://cloud.google.com/docs/authentication).

The library requires an external provider of access tokens to access Google Cloud services. The provider must contain an *acquireAccessToken()* method that takes one required parameter, a handler that is called when an access token is acquired or an error occurs. The handler takes two required parameters: *token*, a string representation of access token, and *error*, a string with error details or null if no error occurred. You can either write an application or use an external library, e.g. [OAuth2.JWTProfile.Client OAuth2 library](https://github.com/electricimp/OAuth-2.0), which contains the *acquireAccessToken()* method.

##### Example: OAuth2 JWTProfile Access Token Provider

```squirrel
// GooglePubSub library
#require "GooglePubSub.agent.lib.nut:1.0.0"

// Obtain Access Tokens Provider using OAuth2 library

// AWS Lambda libraries - are used for RSA-SHA256 signature calculation
#require "AWSRequestV4.class.nut:1.0.2"
#require "AWSLambda.agent.lib.nut:1.0.0"

// OAuth 2.0 library
#require "OAuth2.agent.lib.nut:1.0.0"

// Substitute with real values
const GOOGLE_ISS = "...";
const GOOGLE_SECRET_KEY = "...";
const AWS_LAMBDA_REGION = "...";
const AWS_ACCESS_KEY_ID = "...";
const AWS_SECRET_ACCESS_KEY = "...";

// external service to sign requests
local lambda = AWSLambda(AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY);

// configuration for OAuth2
local config = {
    "iss"         : GOOGLE_ISS,
    "jwtSignKey"  : GOOGLE_SECRET_KEY,
    "scope"       : "https://www.googleapis.com/auth/pubsub",
    "rs256signer" : lambda
};

// obtaining Access Tokens Provider
local oAuthTokenProvider = OAuth2.JWTProfile.Client(OAuth2.DeviceFlow.GOOGLE, config);

// Instantiation of Topics and Publisher parts of GooglePubSub library

const PROJECT_ID = "Google_Cloud_Project_ID";
topics <- GooglePubSub.Topics(PROJECT_ID, oAuthTokenProvider);

const TOPIC_NAME = "my_topic";
publisher <- GooglePubSub.Publisher(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME);
```

### Callbacks and Error Processing

All requests that are made to Google Cloud Pub/Sub service are asynchronous. Every method that sends a request can take an optional callback parameter, a function which will be called when the operation is completed, successfully or not. Details of every callback are described in the corresponding methods.

Every callback has at least one parameter - *error* - an instance of *GooglePubSub.Error* class. If *error* is `null` the operation has been executed successfully. Otherwise, *error* contains the details of the occurred error:

- *type* - error type
- *details* - human readable details of the error
- *httpStatus* - the returned HTTP status code (not for all error types)
- *httpResponse* - response body of the failed request (not for all error types)

Error types are the following:

- *PUB_SUB_ERROR.LIBRARY_ERROR* &mdash; This is reported if the library has been wrongly initialized or invalid arguments are passed into the method. Usually it indicates an issue during an application development which should be fixed during debugging and therefore should not occur after the application has been deployed. The actual error details are provided in *GooglePubSub.Error.details* field.

- *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* &mdash; This is reported if HTTP request to Google Cloud Pub/Sub service fails. This error may occur during the normal execution of an application. The application logic should process this error. The error details are provided in *GooglePubSub.Error.details*, *GooglePubSub.Error.httpStatus* and *GooglePubSub.Error.httpResponse* fields.

- *PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE* &mdash; This indicates an unexpected behavior of Google Cloud Pub/Sub service, such as a response which does not correspond to the Google Cloud Pub/Sub REST API specification. The error details are provided in *GooglePubSub.Error.details* and *GooglePubSub.Error.httpResponse* fields.

## Message Class

*GooglePubSub.Message* is an auxiliary class that represents Google Cloud Pub/Sub message - a combination of data (any type) and attributes (a table) that move through the service. Both *data* and *attributes* are optional.

*GooglePubSub.Message* instances are received using [GooglePubSub.PullSubscriber](#pullsubscriber-class) and [GooglePubSub.PushSubscriber](#pushsubscriber-class) classes.

*GooglePubSub.Message* instances may be sent to Pub/Sub service using [GooglePubSub.Publisher](#publisher-class) class.

```squirrel
local gMsg = GooglePubSub.Message("Test message", { "attr1" : "value1", "attr2" : "value2" });
```

## Topics Class

Topic is a named entity that represents a feed of messages. Any message is sent to Google Cloud Pub/Sub service on a specified topic.

*GooglePubSub.Topics* class provides access to Pub/Sub topics management methods.
One instance of this class is enough to manage all topics of one Project specified in the class constructor.
It can be used to check existence, create, delete topics of the Project and obtain a list of the topics registered to the Project.

Topic name is an identifier of the topic, unique within the Project.

*GooglePubSub.Topics* class allows to manage Pub/Sub topics but is not intended to send messages.
For message sending the library provides another component - [GooglePubSub.Publisher](#publisher-class) class.

#### Examples

```squirrel
const TOPIC_NAME = "my_topic";

topics <- GooglePubSub.Topics(PROJECT_ID, oAuthTokenProvider);

// create topic if it doesn't exist
topics.obtain(TOPIC_NAME, { "autoCreate" : true }, function(error) {
    if (error) {
        server.error(error.details);
    } else {
        // the topic exists or has been created
        // you can now publish or receive messages
    }
});

// remove topic
topics.remove(TOPIC_NAME, function(error) {
    if (error) {
        server.error(error.details);
    } else {
        // the topic removed successfully
    }
});

// get the list of all topics
topics.list({ "paginate" : false }, function(error, topicNames, nextOptions) {
    if (error) {
        server.error(error.details);
    } else {
        // topicNames contains names of all topics registered to the project
        foreach (topic in topicNames) {
            // process topics individually
        }
    }
});

// callback for paginated list of topics
function topicsListCallback(error, topicNames, nextOptions) {
    if (error) {
        server.error(error.details);
    } else {
        // topicNames contains limited number of topic names
        foreach (topic in topicNames) {
            // process topics individually
        }
    }

    if (nextOptions) {
        // more topics exist => continue listing
        topics.list(nextOptions, topicsListCallback);
    }
}

// start paginated list of topics
topics.list({ "paginate" : true, "pageSize" : 5 }, topicsListCallback);
```

## Publisher Class

*GooglePubSub.Publisher* class allows the agent to publish messages to a specific topic of Google Cloud Pub/Sub service.
One instance of this class publishes messages to one topic which belongs to a Project. Both the project and topic are specified in the class constructor.

The class provides only one method - *GooglePubSub.Publisher.publish()* - which accepts the following data as a message:
- raw data of any type. It may be used to send a data value without attributes.
- an instance of [GooglePubSub.Message](#message-class) class. It may be used to send a message with attributes, with or without a data value.
- an array of raw values or an array of [GooglePubSub.Message](#message-class) instances. It may be used to send several messages with one request.

#### Examples

```squirrel
const TOPIC_NAME = "my_topic";
publisher <- GooglePubSub.Publisher(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME);

// publish simple message
publisher.publish("Hello!", function(error, messageIds) {
    if (!error) {
        // message published successfully
    }
});

// publish array of compound messages
publisher.publish(
    [
        { "temperature" : 36.6, "humidity" : 80 },
        { "temperature" : 37.2, "humidity" : 75 }
    ],
    function(error, messageIds) {
        if (!error) {
            // message published successfully
        }
    });

// publish message with attributes using GooglePubSub.Message class
publisher.publish(
    GooglePubSub.Message("Test message", { "attr1" : "value1", "attr2" : "value2" }),
    function(error, messageIds) {
        if (!error) {
            // message published successfully
        }
    });
```

## Subscriptions Class

Subscription is a named entity that represents an interest in receiving messages on a particular topic. Any message is received from a specified Google Cloud Pub/Sub subscription.

There are two types of subscriptions:
- pull subscription. An entity which want to receive messages (subscriber entity) initiates requests to Pub/Sub service to retrieve messages. The received messages should be explicitly acknowledged.
- push subscription. Pub/Sub service sends each message as an HTTPs request to the subscriber entity at a pre-configured endpoint. The endpoint acknowledges the message by returning an HTTP success status code.

Subscription name is an identifier of the subscription, unique within the Project.

More information about Google Cloud Pub/Sub subscriptions is [here](https://cloud.google.com/pubsub/docs/subscriber).

*GooglePubSub.Subscriptions* class provides access to Pub/Sub subscriptions management methods.
One instance of this class is enough to manage all subscriptions of one Project specified in the class constructor.
It can be used to check existence, create, configure, delete subscriptions of the Project and obtain a list of the subscriptions registered to the Project or related to a topic.
The class allows to management for both, pull and push, types of subscriptions.

A subscription configuration is encapsulated in *GooglePubSub.SubscriptionConfig* class that may include additional configuration parameters for a push subscription which are encapsulated in *GooglePubSub.PushConfig* class. The push subscription configuration has *pushEndpoint* parameter - URL to a custom endpoint that messages should be pushed to.

It is possible to change a push subscription to a pull one or vice versa - using *GooglePubSub.Subscriptions.modifyPushConfig()* method.

*GooglePubSub.Subscriptions* class allows to the imp to manage Pub/Sub subscriptions but is not intended to receive messages.
For message receiving the library provides two other components:

- To receive messages from a pull subscription, [GooglePubSub.PullSubscriber](#pullsubscriber-class) class may be used.

- To receive messages from a push subscription, [GooglePubSub.PushSubscriber](#pullsubscriber-class) class may be used. This only works for a subscription configured with a push endpoint which is based on URL of the IMP agent where the library is running. Auxiliary *GooglePubSub.Subscriptions.getImpAgentEndpoint()* method may be used to generate such an URL and, after that, the URL may be specified as a push endpoint.

To create and use any push subscription, the push endpoint must be registered in Google Cloud Platform as described in "Registering endpoints" section of the [Google Cloud Pub/Sub Push Subscriber Guide](https://cloud.google.com/pubsub/docs/push).

#### Examples

```squirrel
const TOPIC_NAME = "my_topic";
const SUBSCR_NAME = "my_subscription";
const SUBSCR_NAME_2 = "my_other_subscription";
const PUSH_SUBSCR_NAME = "my_push_subscription";

subscrs <- GooglePubSub.Subscriptions(PROJECT_ID, oAuthTokenProvider);

// check if subscription exists
subscrs.obtain(SUBSCR_NAME, null, function(error, subscrConfig) {
    if (error) {
        if (error.type == PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED && error.httpStatus == 404) {
            // the subscription doesn't exist
        } else {
            // a different error occurs
            server.error(error.details);
        }
    } else {
        // the subscription exists
    }
});

// get or create pull subscription
subscrs.obtain(
    SUBSCR_NAME_2,
    { "autoCreate" : true, "subscrConfig" : GooglePubSub.SubscriptionConfig(TOPIC_NAME) },
    function(error, subscrConfig) {
        if (error) {
            server.error(error.details);
        } else {
            // the subscription is obtained
        }
    });

// get or create push subscription based on imp Agent URL
subscrs.obtain(
    PUSH_SUBSCR_NAME,
    {
        "autoCreate" : true,
        "subscrConfig" : GooglePubSub.SubscriptionConfig(
            TOPIC_NAME,
            10,    // ackDeadlineSeconds
            GooglePubSub.PushConfig(subscrs.getImpAgentEndpoint()))
    },
    function(error, subscrConfig) {
        if (error) {
            server.error(error.details);
        } else {
            // the subscription is obtained
        }
    });

// remove subscription
subscrs.remove(SUBSCR_NAME_2, function(error) {
    if (error) {
        server.error(error.details);
    } else {
        // the subscription removed successfully
    }
});

// get a list of subscriptions related to the topic
subscrs.list({ "topicName" : TOPIC_NAME }, function(error, subscrNames, nextOptions) {
    if (error) {
        server.error(error.details);
    } else {
        // subscrNames contains names of all subscriptions related to the topic TOPIC_NAME
        foreach (subscr in subscrNames) {
            // process subscriptions individually
        }
    }
});
```

## PullSubscriber Class

*GooglePubSub.PullSubscriber* class allows to receive messages from a pull subscription of Google Cloud Pub/Sub service and acknowledge the received messages. One instance of this class receives messages from one pull subscription which belongs to a Project. The both, project and subscription, are specified in the class constructor.

The received messages are provided as instances of [GooglePubSub.Message](#message-class) class.

*GooglePubSub.PullSubscriber* class provides three types of pull operation:

- one shot pulling - *GooglePubSub.PullSubscriber.pull()* method. It checks for new messages and calls a callback immediately, with or without the messages. It's a basic pull operation. It might be used in a universal or in any custom use case, and/or when other pull operations are not convenient.

- periodic pulling - *GooglePubSub.PullSubscriber.periodicPull()* method. It periodically checks for new messages and calls a callback if new messages are available at a time of a check. It might be used in a case when an application does not need to react on new messages as soon as possible but rather checks and get messages periodically. Make sure the required period is not too small, otherwise consider to use *GooglePubSub.PullSubscriber.pendingPull()* method.

- pending (waiting) pulling - *GooglePubSub.PullSubscriber.pendingPull()* method. It waits for new messages and calls a callback when new messages appear. Optionally, it may automatically recall the same pending pull operation after the callback is executed. This operation might be used in a case when an application needs to react on new messages as soon as possible.

Only one pull operation can be active at a time. An attempt to call a new pull operation while another one is active fails with *PUB_SUB_ERROR.LIBRARY_ERROR* error.
Periodic and pending pull operations may be canceled by a special method - *GooglePubSub.PullSubscriber.stopPull()*. 

Every pull method has an optional parameter to specify a maximum number of messages returned in the method's callback. Note that Google Cloud Pub/Sub service may return fewer messages than the specified maximum number even if there are more messages currently available in the subscription.

There are two ways to acknowledge the received messages:

- Every pull method has an optional *autoAck* parameter. When it is set to *true* the received messages are automatically acknowledged by the library. It is a recommended way for most of use cases.

- There is *GooglePubSub.PullSubscriber.ack()* method to manually acknowledge messages. The method accepts instances of [GooglePubSub.Message](#message-class) class which are received using the pull methods, as well as message acknowledgment IDs which may be obtained from the received messages.

#### Examples

```squirrel
const SUBSCR_NAME = "my_subscription";
pullSubscriber <- GooglePubSub.PullSubscriber(PROJECT_ID, oAuthTokenProvider, SUBSCR_NAME);

// one shot pulling
pullSubscriber.pull({ "autoAck" : true }, function(error, messages) {
    if (!error && messages.len() > 0) {
        foreach (msg in messages) {
            // process messages individually
            server.log(format("Message received: %s: %s", msg.publishTime, msg.data));
        }
    }
});

// periodic pulling with manual acknowledge
pullSubscriber.periodicPull(5.0, null, function(error, messages) {
    if (!error) {
        pullSubscriber.ack(messages, function(error) {
            if (!error) {
                // messages acknowledged successfully
            }
        });
    }
});

// Pending pulling
pullSubscriber.pendingPull({ "repeat" : true, "autoAck" : true }, function(error, messages) {
    // the callback is executed every time new messages appeared
    if (!error) {
        foreach (msg in messages) {
            // process messages individually
        }
    }
});
```

## PushSubscriber Class

*GooglePubSub.PushSubscriber* class allows to receive messages from a push subscription of Google Cloud Pub/Sub service configured with a push endpoint which is based on URL of the IMP agent where the library is running.
One instance of this class receives messages from one push subscription which belongs to a Project. The both, project and subscription, are specified in the class constructor.

The class provides only one method - *GooglePubSub.PushSubscriber.setMessagesHandler()*. It checks if the specified subscription is configured by appropriate push endpoint URL and sets the specified handler function to be executed every time new messages are received from Pub/Sub service.

The received messages are provided as instances of [GooglePubSub.Message](#message-class) class.
The messages are automatically acknowledged by the library.

#### Examples

```squirrel
const PUSH_SUBSCR_NAME = "my_push_subscription";
pushSubscriber <- GooglePubSub.PushSubscriber(PROJECT_ID, oAuthTokenProvider, SUBSCR_NAME);

function messagesHandler(error, messages) {
    // the handler is executed when incoming messages are received
    if (!error) {
        foreach (msg in messages) {
            // process messages individually
            server.log(format("Message received: %s: %s", msg.publishTime, msg.data));
        }
    }
}

pushSubscriber.setMessagesHandler(messagesHandler, function(error) {
    if (!error) {
        // push messages handler set successfully
    } else if (error.type == PUB_SUB_ERROR.LIBRARY_ERROR) {
        // PushSubscriber cannot be used for the specified subscription
        // (e.g. the subscription's push endpoint does not match the IMP agent URL)
    }
});
```

## IAM Class

Google Identity and Access Management (IAM) functionality allows to manage access control by defining who (members) has what access (role) for which resource.
For example:
- Grant access to any operation with particular topic or subscription to a specific user or group of users.
- Grant access with limited capabilities, such as to only publish messages to a topic, or to only consume messages from a subscription, but not to delete the topic or subscription.

For a detailed description of IAM and its features see [Google Cloud Identity and Access Management Documentation](https://cloud.google.com/iam/docs/overview).

*GooglePubSub.IAM* is an auxiliary class that provides IAM functionality for individual Google Cloud Pub/Sub resources (topics and subscriptions).
It is assumed that this class is not instantiated by a user directly, but *GooglePubSub.Topics.iam()* and *GooglePubSub.Subscriptions.iam()* methods are used to get the instances and execute IAM methods for topics and subscriptions respectively.
One instance of *GooglePubSub.IAM* class is enough to manage access to either all topics or all subscriptions of one Project.

IAM policy representation is encapsulated in *GooglePubSub.IAM.Policy* class.

#### Examples

```squirrel
const TOPIC_NAME = "my_topic";
topics <- GooglePubSub.Topics(PROJECT_ID, oAuthTokenProvider);

// get the access control policy for the topic
topics.iam().getPolicy(TOPIC_NAME, function(error, policy) {
    if (error) {
        server.error(error.details);
    } else {
        // the policy obtained successfully
        foreach (binding in policy.bindings) {
            // process policy bindings
            server.log(format(
                "binding %s : %s",
                binding.role,
                binding.members.reduce(function(prev, curr) { return (prev + ", " + curr); })));
        }
    }
});

const SUBSCR_NAME = "my_subscription";
subscrs <- GooglePubSub.Subscriptions(PROJECT_ID, oAuthTokenProvider);

local testedPermissions = ["pubsub.subscriptions.get", "pubsub.subscriptions.delete"];

// test subscription permissions
subscrs.iam().testPermissions(
    SUBSCR_NAME,
    testedPermissions,
    function(error, returnedPermissions) {
        if (!error) {
            // returnedPermissions contains subset of testedPermissions that allowed for the subscription
        }
    });
```

## More Examples

Working examples are provided in [Examples](./Examples) folder and described [here](./Examples/README.md).

## License

The Google-PubSub library is licensed under the [MIT License](./LICENSE)



# Google PubSub Library API Details

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




