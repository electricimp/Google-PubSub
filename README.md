# GooglePubSub

This library lets your agent code connect to [Google’s Cloud Pub/Sub service](https://cloud.google.com/pubsub). It makes use of the [Google Cloud Pub/Sub REST API](https://cloud.google.com/pubsub/docs/reference/rest).

**To add this library to your project, add** `#require "GooglePubSub.agent.lib.nut:1.1.1"` **to the top of your agent code.**

![Build Status](https://cse-ci.electricimp.com/app/rest/builds/buildType:(id:GooglePubSub_BuildAndTest)/statusIcon)

## Examples

Working examples with step-by-step instructions are provided in the [Examples](./Examples) directory and described [here](./Examples/README.md).

## The Google Cloud Pub/Sub Service

[Google Cloud Pub/Sub](https://cloud.google.com/pubsub/docs/overview) is a publish/subscribe service &mdash; a messaging service where the senders of messages are decoupled from the receivers of those messages. There are five main entities used by the Pub/Sub service:

- **Message** The data (with optional attributes) that moves through the service.
- **Topic** A named entity that represents a feed of messages.
- **Subscription** A named entity that represents an interest in receiving messages on a particular topic.
- **Publisher** An entity that creates messages and sends (publishes) them to the messaging service on a specified topic.
- **Subscriber** An entity that receives messages on a specified subscription.

Communication between publishers and subscribers can be one-to-many, many-to-one or many-to-many.

Before working with Google Cloud Pub/Sub Service you need to:

- Register with the Google Cloud Platform.
- Create and configure a [Google Cloud Project](#google-cloud-project).

### Google Cloud Projects

A Google Cloud Project is the component of the Google Cloud Platform which allows users to create, configure and use all Cloud Platform resources and services, including Pub/Sub. All Pub/Sub topics and subscriptions are owned by a specific project; the library’s classes needs to instanced for each project you work with.

You can view example that will show you how to create and configure a Google Cloud Project [here](./Examples/README.md#google-cloud-account-configuration). For more information, please see [Google Cloud Project resource description](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects) and [Creating and Managing Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

## Library Usage

The library API is described in detail in a [separate document](./GooglePubSubAPI.md).

### Main Classes

The library consists of five independent classes. You can instantiate and use any of these classes in your agent code as required by your application. They are:

- [GooglePubSub.Topics](#topics-class) &mdash; Provides Pub/Sub topics management. One instance of this class is enough to manage all of the topics in one project.
- [GooglePubSub.Publisher](#publisher-class): &mdash; Allows an agent to publish messages to a topic. One instance of this class allows your code to publish messages to one topic.
- [GooglePubSub.Subscriptions](#subscriptions-class) &mdash; Provides Pub/Sub subscriptions management. One instance of this class is enough to manage all the subscriptions in one project.
- [GooglePubSub.PullSubscriber](#pullsubscriber-class) &mdash; Allows your code to receive messages from a pull subscription. One instance of this class allows your code to receive messages from one pull subscription.
- [GooglePubSub.PushSubscriber](#pushsubscriber-class) &mdash; Allows your code to receive messages from a push subscription configured with the agent URL as a push endpoint. One instance of this class allows your code to receive messages from one push subscription.

To instantiate any of these classes you need to have:

- [A Google Cloud Project ID](#google-cloud-project)
- [A provider of access tokens](#access-token-provider) suitable for Google Cloud Pub/Sub service request authentication.

#### Access Token Provider

The library requires an external provider of access tokens to gain access to Google Cloud services. The provider must contain an *acquireAccessToken()* method that takes one required parameter: a handler that is called when an access token is acquired or an error occurs. The handler itself has two required parameters: *token*, a string representation of the access token, and *error*, a string with error details (or `null` if no error occurred). You can either write the provider code yourself or use an external library such as Electric Imp’s [OAuth2.JWTProfile.Client OAuth2 library](https://github.com/electricimp/OAuth-2.0), which contains the required *acquireAccessToken()* method.

For information about Google Cloud Pub/Sub service authentication, see [this page](https://cloud.google.com/docs/authentication).

##### Example: OAuth2 JWTProfile Access Token Provider

```squirrel
// GooglePubSub library
#require "GooglePubSub.agent.lib.nut:1.1.1"

// OAuth 2.0 library
#require "OAuth2.agent.lib.nut:2.0.0"

// Substitute with real values
const GOOGLE_ISS = "...";
const GOOGLE_SECRET_KEY = "...";

// configuration for OAuth2
local config = {
    "iss"         : GOOGLE_ISS,
    "jwtSignKey"  : GOOGLE_SECRET_KEY,
    "scope"       : "https://www.googleapis.com/auth/pubsub"
};

// Obtain the Access Tokens Provider
local oAuthTokenProvider = OAuth2.JWTProfile.Client(OAuth2.DeviceFlow.GOOGLE, config);

// Instantiation of topics and publisher components
const PROJECT_ID = "<your_google_cloud_project_id>";
topics <- GooglePubSub.Topics(PROJECT_ID, oAuthTokenProvider);

const TOPIC_NAME = "<your_topic_name>";
publisher <- GooglePubSub.Publisher(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME);
```

### Callbacks and Error Processing

All requests that are made to the Google Cloud Pub/Sub service occur asynchronously. Every method that sends a request has an optional parameter which takes a callback function that will be called when the operation is completed, successfully or not. The callbacks’ parameters are listed in the corresponding method documentation, but every callback has at least one parameter, *error*. If *error* is `null`, the operation has been executed successfully. Otherwise, *error* is an instance of the *GooglePubSub.Error* class and contains the details of the error, accessed through the following properties:

- *type* &mdash; Error type (see below).
- *details* &mdash; Human readable details of the error.
- *httpStatus* &mdash; The returned HTTP status code (not present for all error types).
- *httpResponse* &mdash; Response body of the failed request (not present for all error types).

The error type will be one of the following:

- *PUB_SUB_ERROR.LIBRARY_ERROR* &mdash; This is reported if the library has been wrongly initialized or invalid arguments are passed into a method. Usually it indicates an issue during an application development which should be fixed during debugging and therefore should not occur after the application has been deployed. Includes the *GooglePubSub.Error.details* property.

- *PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED* &mdash; This is reported if the HTTP request to Google Cloud Pub/Sub service fails. This error may occur during the normal execution of an application. The application logic should process this error. Includes the *GooglePubSub.Error.details*, *GooglePubSub.Error.httpStatus* and *GooglePubSub.Error.httpResponse* properties.

- *PUB_SUB_ERROR.PUB_SUB_UNEXPECTED_RESPONSE* &mdash; This indicates an unexpected behavior by the Google Cloud Pub/Sub service, such as a response which does not correspond to the Google Cloud Pub/Sub REST API specification. Includes the *GooglePubSub.Error.details* and *GooglePubSub.Error.httpResponse* fields.

## Message Class

GooglePubSub.Message is an auxiliary class that represents a Google Cloud Pub/Sub message, which is a combination of *data* (of any type) and *attributes* (a table) that moves through the service. Both *data* and *attributes* are optional.

GooglePubSub.Message instances are retrieved using the [GooglePubSub.PullSubscriber](#pullsubscriber-class) and/or [GooglePubSub.PushSubscriber](#pushsubscriber-class) classes.

GooglePubSub.Message instances may be sent to the Pub/Sub service using the [GooglePubSub.Publisher](#publisher-class) class.

```squirrel
local gMsg = GooglePubSub.Message("Test message", { "attr1" : "value1", "attr2" : "value2" });
```

## Topics Class

A topic is a named entity that represents a message channel. Each message is sent to the Google Cloud Pub/Sub service via a specified topic. Each topic name must be unique to its project.

The GooglePubSub.Topics class can be used to the check the existence of a topic within a project; create and delete topics from the project; and obtain a list of a project’s topics.

The GooglePubSub.Topics class is not intended to send messages &mdash; use the [GooglePubSub.Publisher](#publisher-class) class.

#### Examples

```squirrel
const TOPIC_NAME = "<my_topic_name>";

topics <- GooglePubSub.Topics(PROJECT_ID, oAuthTokenProvider);

// Create topic if it doesn't exist
topics.obtain(TOPIC_NAME, { "autoCreate" : true }, function(error) {
    if (error) {
        server.error(error.details);
    } else {
        // The topic exists or has been created.
        // You can now publish or receive messages
    }
});

// Remove topic
topics.remove(TOPIC_NAME, function(error) {
    if (error) {
        server.error(error.details);
    } else {
        // The topic was removed successfully
    }
});

// Get the list of all topics
topics.list({ "paginate" : false }, function(error, topicNames, nextOptions) {
    if (error) {
        server.error(error.details);
    } else {
        // 'topicNames' contains names of all the topics registered to the project
        foreach (topic in topicNames) {
            // Process topics individually
        }
    }
});

// Callback for paginated list of topics
function topicsListCallback(error, topicNames, nextOptions) {
    if (error) {
        server.error(error.details);
    } else {
        // 'topicNames' contains limited number of topic names
        foreach (topic in topicNames) {
            // Process topics individually
        }
    }

    if (nextOptions) {
        // More topics exist, so continue listing
        topics.list(nextOptions, topicsListCallback);
    }
}

// Retrieve a paginated list of topics
topics.list({ "paginate" : true, "pageSize" : 5 }, topicsListCallback);
```

## Publisher Class

The GooglePubSub.Publisher class allows the agent to publish messages to a specific topic. One instance of this class publishes messages to one of a project’s topics. Both the project and topic are specified in the class constructor.

The class provides only one method, *GooglePubSub.Publisher.publish()*, which accepts the following data as a message:

- Raw data of any type. This may be used to send a data value without attributes.
- An instance of the [GooglePubSub.Message](#message-class) class. It may be used to send a message with attributes, with or without a data value.
- An array of raw values or an array of [GooglePubSub.Message](#message-class) instances. It may be used to send several messages with one request.

#### Examples

```squirrel
const TOPIC_NAME = "<my_topic_name>";
publisher <- GooglePubSub.Publisher(PROJECT_ID, oAuthTokenProvider, TOPIC_NAME);

// Publish a simple message
publisher.publish("Hello!", function(error, messageIds) {
    if (!error) {
        // Message published successfully
    }
});

// Publish an array of compound messages
publisher.publish(
    [
        { "temperature" : 36.6, "humidity" : 80 },
        { "temperature" : 37.2, "humidity" : 75 }
    ],
    function(error, messageIds) {
        if (!error) {
            // Message published successfully
        }
    });

// Publish a message with attributes using GooglePubSub.Message class
publisher.publish(
    GooglePubSub.Message("Test message", { "attr1" : "value1", "attr2" : "value2" }),
    function(error, messageIds) {
        if (!error) {
            // Message published successfully
        }
    });
```

## Subscriptions Class

A subscription is a named entity that represents an interest in receiving messages on a particular topic. Messages are received from a specified Google Cloud Pub/Sub subscription. Subscription names must be unique within the project.

There are two types of subscription:

- Pull &mdash; A subscriber that wants to receive messages manually initiates requests to the Pub/Sub service to retrieve messages. The received messages should be explicitly acknowledged.
- Push &mdash; The Pub/Sub service sends each message as an HTTP request to the subscriber at a pre-configured endpoint. The endpoint acknowledges the message by returning an HTTP success status code.

The class allows your to manage both pull and push subscriptions. It is possible to change a push subscription to a pull one, or vice versa, using the *GooglePubSub.Subscriptions.modifyPushConfig()* method.

One instance of GooglePubSub.Subscriptions is sufficient to manage all of the subscriptions belonging to the project specified in the class constructor. It can be used to check the existence of a subscription; to create, configure and delete the project’s subscriptions; and to obtain a list of the subscriptions registered to the project or related to a topic.

A subscription configuration is encapsulated in an instance of the GooglePubSub.SubscriptionConfig class. Additional configuration parameters for a push subscription are encapsulated in an instance of GooglePubSub.PushConfig which has a *pushEndpoint* property: the URL of the endpoint that messages should be pushed to.

### Receiving Messages

The GooglePubSub.Subscriptions class allows to the agent to manage Pub/Sub subscriptions but is not intended to receive messages. To receive messages, the library provides two other components:

- To receive messages from a pull subscription, use the [GooglePubSub.PullSubscriber](#pullsubscriber-class) class.
- To receive messages from a push subscription, use the [GooglePubSub.PushSubscriber](#pullsubscriber-class) class. This only works for a subscription configured with a push endpoint which is based on the URL of the agent where the library is running. The method *GooglePubSub.Subscriptions.getImpAgentEndpoint()* may be used to generate such an URL. To create and use any push subscription, the push endpoint must be registered with the Google Cloud Platform as described in the ‘Registering endpoints’ section of the [Google Cloud Pub/Sub Push Subscriber Guide](https://cloud.google.com/pubsub/docs/push).

#### Examples

```squirrel
const TOPIC_NAME = "<my_topic_name>";
const SUBSCR_NAME = "<my_pull_subscription_name>";
const SUBSCR_NAME_2 = "<my_other_pull_subscription_name>";
const PUSH_SUBSCR_NAME = "<my_push_subscription_name>";

subscrs <- GooglePubSub.Subscriptions(PROJECT_ID, oAuthTokenProvider);

// Check if the subscription exists
subscrs.obtain(SUBSCR_NAME, null, function(error, subscrConfig) {
    if (error) {
        if (error.type == PUB_SUB_ERROR.PUB_SUB_REQUEST_FAILED && error.httpStatus == 404) {
            // The subscription doesn't exist
        } else {
            // A different error occurs
            server.error(error.details);
        }
    } else {
        // The subscription exists
    }
});

// Get or create a pull subscription
subscrs.obtain(
    SUBSCR_NAME_2,
    { "autoCreate" : true, "subscrConfig" : GooglePubSub.SubscriptionConfig(TOPIC_NAME) },
    function(error, subscrConfig) {
        if (error) {
            server.error(error.details);
        } else {
            // The subscription is obtained
        }
    });

// Get or create a push subscription based on the agent URL
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
            // The subscription is obtained
        }
    });

// Remove a subscription
subscrs.remove(SUBSCR_NAME_2, function(error) {
    if (error) {
        server.error(error.details);
    } else {
        // the subscription removed successfully
    }
});

// Get a list of subscriptions related to the topic
subscrs.list({ "topicName" : TOPIC_NAME }, function(error, subscrNames, nextOptions) {
    if (error) {
        server.error(error.details);
    } else {
        // 'subscrNames' contains names of all subscriptions related to the topic
        foreach (subscr in subscrNames) {
            // Process subscriptions individually
        }
    }
});
```

## PullSubscriber Class

The GooglePubSub.PullSubscriber class allows your code to receive messages from a pull subscription and to acknowledge their receipt. One instance of this class receives messages from one of the project’s pull subscription. Both project and subscription are specified in the class constructor.

The received messages are provided as instances of the [GooglePubSub.Message](#message-class) class.

The GooglePubSub.PullSubscriber class provides three types of pull operation:

- One-shot &mdash; A basic pull operation. Call the *GooglePubSub.PullSubscriber.pull()* method. This checks for new messages and triggers the callback immediately, with or without the messages. It might be used in a universal or in any custom use case, or when other pull operations are not convenient.

- Periodic &mdash; Call the *GooglePubSub.PullSubscriber.periodicPull()* method. This periodically checks for new messages and triggers the callback if new messages are available. It might be used when an application does not need to deal with new messages as quickly as possible. If the required period is small, consider using a pending pull *(see below)*.

- Pending (waiting) &mdash; Call the *GooglePubSub.PullSubscriber.pendingPull()* method. This waits for new messages and triggers the callback when new messages appear. Optionally, it may automatically recall the same pending pull operation after the callback is executed. This operation might be used in a case when an application needs to deal with new messages as quickly as possible.

Only one pull operation per subscription can be active at a time. An attempt to call a new pull operation while another one is active will fail with a *PUB_SUB_ERROR.LIBRARY_ERROR* error.

Periodic and pending pull operations may be cancelled by calling the method *GooglePubSub.PullSubscriber.stopPull()*.

Every pull method has an optional parameter to specify the maximum number of messages returned in the callback. Note that the Google Cloud Pub/Sub service may return fewer messages than the specified maximum number even if there are more messages currently available in the subscription.

### Message Acknowledgement

There are two ways to acknowledge the receipt of a message:

- Every pull method has an optional *autoAck* parameter. When it is set to `true`, the received messages are automatically acknowledged by the library. This is the recommended setting.
- Call *GooglePubSub.PullSubscriber.ack()* to manually acknowledge messages. The method accepts the instances of the [GooglePubSub.Message](#message-class) class which are received using the pull methods, as well as message acknowledgment IDs, which may be obtained from the received messages.

#### Examples

```squirrel
const SUBSCR_NAME = "<my_pull_subscription_name>";
pullSubscriber <- GooglePubSub.PullSubscriber(PROJECT_ID, oAuthTokenProvider, SUBSCR_NAME);

// One-shot pulling
pullSubscriber.pull({ "autoAck" : true }, function(error, messages) {
    if (!error && messages.len() > 0) {
        foreach (msg in messages) {
            // Process messages individually
            server.log(format("Message received: %s: %s", msg.publishTime, msg.data));
        }
    }
});

// Periodic pulling with manual acknowledge
pullSubscriber.periodicPull(5.0, null, function(error, messages) {
    if (!error) {
        pullSubscriber.ack(messages, function(error) {
            if (!error) {
                // Messages acknowledged successfully
            }
        });
    }
});

// Pending pulling
pullSubscriber.pendingPull({ "repeat" : true, "autoAck" : true }, function(error, messages) {
    // The callback is executed every time new messages arrive
    if (!error) {
        foreach (msg in messages) {
            // Process messages individually
        }
    }
});
```

## PushSubscriber Class

The GooglePubSub.PushSubscriber class lets the agent receive messages from a push subscription configured with a push endpoint based on the URL of the agent where the library is running. One instance of this class receives messages from one push subscription. Both the subscription and the project it belongs to, are specified in the class constructor.

The class provides only one method: *GooglePubSub.PushSubscriber.setMessagesHandler()*. This checks if the specified subscription is configured with an appropriate endpoint URL and sets the specified handler function to be executed every time new messages are received.

The received messages are provided as instances of the [GooglePubSub.Message](#message-class) class and are automatically acknowledged by the library.

#### Examples

```squirrel
const PUSH_SUBSCR_NAME = "<my_push_subscription_name>";
pushSubscriber <- GooglePubSub.PushSubscriber(PROJECT_ID, oAuthTokenProvider, PUSH_SUBSCR_NAME);

function messageHandler(error, messages) {
    // The handler is executed when incoming messages are received
    if (!error) {
        foreach (msg in messages) {
            // Process messages individually
            server.log(format("Message received: %s: %s", msg.publishTime, msg.data));
        }
    }
}

pushSubscriber.setMessagesHandler(messageHandler, function(error) {
    if (!error) {
        // Push messages handler set successfully
    } else if (error.type == PUB_SUB_ERROR.LIBRARY_ERROR) {
        // PushSubscriber cannot be used for the specified subscription
        // (e.g. the subscription's push endpoint does not match the agent URL)
    }
});
```

## IAM Class

Google’s Identity and Access Management (IAM) functionality allows your code to manage access control by defining who (members) has what access (role) for which resource. For example:

- Grant access to any operation for a particular topic or subscription to a specific user or group of users.
- Grant access with limited capabilities, such as only publish messages to a certain topic, or only consume messages from a certain subscription, but not to delete the topic or the subscription.

For a detailed description of IAM and its features, please see the [Google Cloud Identity and Access Management Overview](https://cloud.google.com/iam/docs/overview).

GooglePubSub.IAM is the class that provides IAM functionality for individual Google Cloud Pub/Sub resources (topics and subscriptions). This class should not be instantiated by a user directly; instead the *GooglePubSub.Topics.iam()* and *GooglePubSub.Subscriptions.iam()* methods are used to get the instances and to execute IAM methods for topics and subscriptions, respectively.

One instance of GooglePubSub.IAM class is sufficient to manage access to either all the topics or all the subscriptions belonging to one project.

IAM policy representation is encapsulated in instances of the GooglePubSub.IAM.Policy class.

#### Examples

```squirrel
const TOPIC_NAME = "<my_topic_name>";
topics <- GooglePubSub.Topics(PROJECT_ID, oAuthTokenProvider);

// Get the access control policy for the topic
topics.iam().getPolicy(TOPIC_NAME, function(error, policy) {
    if (error) {
        server.error(error.details);
    } else {
        // The policy was obtained successfully
        foreach (binding in policy.bindings) {
            // Process policy bindings
            server.log(format(
                "Binding %s : %s",
                binding.role,
                binding.members.reduce(function(prev, curr) { return (prev + ", " + curr); })));
        }
    }
});

const SUBSCR_NAME = "<my_subscription_name>";
subscrs <- GooglePubSub.Subscriptions(PROJECT_ID, oAuthTokenProvider);

local testedPermissions = ["pubsub.subscriptions.get", "pubsub.subscriptions.delete"];

// Test subscription permissions
subscrs.iam().testPermissions(
    SUBSCR_NAME,
    testedPermissions,
    function(error, returnedPermissions) {
        if (!error) {
            // 'returnedPermissions' contains the subset of 'testedPermissions' that allowed for the subscription
        }
    });
```

## License

The GooglePubSub library is licensed under the [MIT License](./LICENSE)
