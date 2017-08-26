# GooglePubSub Examples

## Examples Overview

This readme describes example applications provided with [GooglePubSub library](../README.md).

Before running an example application you need to set the configuration constants in the application (IMP agent) source code. See [Examples Setup](#examples-setup) section below.

The following example applications are provided:
- *ProjectInfo*
- *Publisher*
- *PullSubscriber*
- *PushSubscriber*

To see the messages comming you need to run *PullSubscriber* and/or *PushSubscriber* examples in parallel with *Publisher* example.
The recommended order of the examples running:
- run *Publisher* example on the agent of your first IMP device
- run *PullSubscriber* example on the agent of your second IMP device
- run *PushSubscriber* example on the agent of your third IMP device

*ProjectInfo* example may be ran many times at any moment. But note, it displays nothing if no topics/subscriptions have been created in your project (e.g. by running other provided examples). 

### ProjectInfo Example

This example collects and prints information about Pub/Sub topics and subscriptions which belong to the specified (by *PROJECT_ID* configuration constant) Google Cloud Project.

The following information is printed out:
- list of topics
- IAM Policy of every topic
- list of subscriptions related to every topic
- configuration of every subscription
- IAM Policy of every subscription

![ProjectInfo example](http://imgur.com/VDKgV7c.png)

### Publisher Example

This example publishes Pub/Sub Messages to the *"test_topic"* Pub/Sub topic which belong to the specified (by *PROJECT_ID* configuration constant) Google Cloud Project.

- *"test_topic"* topic is created if it does not exist.
- One message is published every 10 seconds.
- Every message contains:
  - message data - a "fake" data, integer, starts from 1 and increases by 1 with every message. Restarts from 1 when the example is restarted.
  - *"measureTime"* attribute - measurement time in seconds since the epoch format.

![Publisher example](http://imgur.com/tggTPYg.png)

### PullSubscriber Example

This example receives Pub/Sub Messages from the *"test_pull_subscription"* Pub/Sub pull subscription which belong to the specified (by *PROJECT_ID* configuration constant) Google Cloud Project and prints the messages content. 

- *"test_pull_subscription"* subscription is created if it does not exist:
  - the subscription is related to *"test_topic"* topic,
  - it is a pull type subscription.
- Messages are received using repeated pending pull operation - *GooglePubSub.PullSubscriber.pendingPull()*.
- Messages are acknowledged automatically using *autoAck* option of the pull operation.
- The following information is printed out for every message:
  - value of the message data,
  - all custom attributes of the message,
  - the standard *"publishTime"* attribute.

![PullSubscriber example](http://imgur.com/WDQ9lGQ.png)

### PushSubscriber Example

This example receives Pub/Sub Messages from the *"test_push_subscription"* Pub/Sub push subscription which belong to the specified (by *PROJECT_ID* configuration constant) Google Cloud Project and prints the messages content.

Additional setup is required before running this application. See [Additional Setup For PushSubscriber Example](#additional-setup-for-pushsubscriber-example) section below.

- *"test_push_subscription"* subscription is created if it does not exist:
  - the subscription is related to *"test_topic"* topic,
  - it is a push type subscription,
  - push endpoint URL is equal to the URL of IMP agent where the application is running,
  - push subscription secret token is *"secret_token"*.
- The following information is printed out for every message:
  - value of the message data,
  - all custom attributes of the message,
  - the standard *"publishTime"* attribute.

![PushSubscriber example](http://imgur.com/HjXJrfz.png)

## Examples Setup

### Common Setup For All Examples

#### Google Cloud account configuration
- Login at [Google Cloud Console](https://console.cloud.google.com) in your web browser.
- If you have an existing project that you want to work with, skip this step. 
Otherwise click "Select a project" link and click "+" in the opened window.
![Project create](http://imgur.com/2FbH9S6.png)
Enter "Project name" and click "Create".
- Click "Select a project" link and choose your project.
Copy ID of your project, the value will be used as **PROJECT_ID** configuration constant value.
![Project select](http://imgur.com/PR9U25p.png)
- In the left side menu choose "Pub/Sub".
![PubSub menu](http://imgur.com/81zNGg1.png)
- Click "Enable API".
![PubSub enable](http://imgur.com/MS7MnZK.png)


#### OAuth 2.0 JWT Profile configuration
- Follow the instructions from [JWT Profile for OAuth 2.0](https://github.com/electricimp/OAuth-2.0/tree/master/examples#jwt-profile-for-oauth-20) to obtain all the required constants for OAuth 2.0 JWT Profile configuration - **GOOGLE_ISS, GOOGLE_SECRET_KEY, AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY**.

#### Example constants setup
- Set the example code configuration constants (**PROJECT_ID, GOOGLE_ISS, GOOGLE_SECRET_KEY, AWS_LAMBDA_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY**) with the values retrieved on the previous steps.
![Examples config](http://imgur.com/G0Mw9uv.png)

### Additional Setup For PushSubscriber Example

#### Register the push endpoint in Google Cloud Platform
- Copy your imp Agent URL from Electric Imp IDE Device Settings.
- Go to [Google Search Console](https://www.google.com/webmasters/tools), enter your imp Agent URL and click "Add a property"
![Search console add property](http://imgur.com/ZFpLQHY.png)
- Download suggested HTML verification file
![Search console download](http://imgur.com/AEe7O69.png)
- Copy the following code to Electric Imp IDE Agent section, substitute GOOGLE_SITE_VERIFICATION value with the whole content of downloaded HTML verification file and click "Build and Run"
```squirrel
const GOOGLE_SITE_VERIFICATION = "...";
http.onrequest(function (request, response) {
    response.send(200, GOOGLE_SITE_VERIFICATION);
});
```
![Imp verification code](http://imgur.com/HzSt05P.png)
- In Google Search Console click to the link "Confirm successful upload by visiting ... in your browser" and then click "Verify".
![Search console steps](http://imgur.com/l8z6WvP.png)
You should receive success message like "Congratulations, you have successfully verified your ownership of ..."
- Go to [Google Cloud Console](https://console.cloud.google.com)
- Select your project.
- In the left side menu choose "APIs & Services", then select "Credentials".
![Credentials](http://imgur.com/ewnRN6i.png)
- Select "Domain verification" and click "Add domain".
![Domain verification](http://imgur.com/XfQwV1f.png)
- Enter your imp Agent URL and click "Add domain".
![Add domain](http://imgur.com/SmNDmsf.png)
