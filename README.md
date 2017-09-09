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

For more information see [Google Cloud Pub/Sub overview](https://cloud.google.com/pubsub/docs/overview)

Before working with Google Cloud Pub/Sub Service you need to:
- register Google Cloud Platform account,
- create and configure [Google Cloud Project](#google-cloud-project).

### Google Cloud Project

Google Cloud Project is a basic entity of Google Cloud Platform which allows users to create, configure and use all Cloud Platform resources and services, including Pub/Sub.
All Pub/Sub Topics and Subscriptions are owned by a specific Project.
To manage Pub/Sub resources associated with different Projects, you may use different instances of the classes from this library.

For more information see [Google Cloud Project resource description](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects) and [Creating and Managing Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

An example of how to create and configure a Google Cloud project see [here](./Examples/README.md#google-cloud-account-configuration).

## Library Usage

The library API is described in details [here](./GooglePubSubAPI).

### Main Components

The library consists of five independent main components (classes). You can instantiate and use any of these components in your IMP agent code depending on your application requirements.

- [GooglePubSub.Topics class](#topics-class): provides access to Pub/Sub Topics management methods. One instance of this class is enough to manage all topics of one Project.

- [GooglePubSub.Publisher class](#publisher-class): allows an imp to publish messages to a topic. One instance of this class allows an imp to publish messages to one topic.

- [GooglePubSub.Subscriptions class](#subscriptions-class): provides access to Pub/Sub Subscriptions management methods. One instance of this class is enough to manage all subscriptions of one Project.

- [GooglePubSub.PullSubscriber class](#pullsubscriber-class): allows an imp to receive messages from a pull subscription. One instance of this class allows an imp to receive messages from one pull subscription.

- [GooglePubSub.PushSubscriber class](#pushsubscriber-class): allows an imp to receive messages from a push subscription configured with that imp's agent URL as a push endpoint. One instance of this class allows an imp to receive messages from one push subscription.
 
### Instantiation

To instantiate any [main component](#main-components) of this library you need to have:

- [Google Cloud Project ID](#google-cloud-project)

- [Provider of access tokens](#access-token-provider) suitable for Google Cloud Pub/Sub service requests authentication.

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

For a detailed description of IAM and its features see [Google Cloud Identity and Access Management overview](https://cloud.google.com/iam/docs/overview).

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
