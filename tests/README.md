# Test Instructions

The tests in the current directory are intended to check the behavior of the GooglePubSub library. The current set of tests check:
- Pub/Sub topics manipulations using GooglePubSub.Topics methods
- Pub/Sub subscriptions manipulations using GooglePubSub.Subscriptions methods
- messages sending using GooglePubSub.Publisher methods
- messages receiving using different GooglePubSub.PullSubscriber and GooglePubSub.PushSubscriber methods
- processing of wrong parameters passed into the library methods

The tests are written for and should be used with [impt](https://github.com/electricimp/imp-central-impt). See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.

The tests for GooglePubSub library require pre-setup described below.

## Google Cloud Account Configuration

- Login at [Google Cloud Console](https://console.cloud.google.com) in your web browser.
- If you have an existing project that you want to work with, skip this step, otherwise click the ‘Select a project’ link and click ‘+’ in the opened window:
![Project create](http://imgur.com/2FbH9S6.png)
Enter a project name and click ‘Create’.
- Click the ‘Select a project’ link and choose your project.
Copy your project’s ID &mdash; it will be used as the *GOOGLE_PROJECT_ID* environment variable.
![Project select](http://imgur.com/PR9U25p.png)
- In the hamburger menu choose ‘Pub/Sub’:
![PubSub menu](http://imgur.com/81zNGg1.png)
- Click ‘Enable API’:
![PubSub enable](http://imgur.com/MS7MnZK.png)

## OAuth 2.0 JWT Profile configuration

Follow the instructions from [JWT Profile for OAuth 2.0](https://github.com/electricimp/OAuth-2.0/tree/master/examples#jwt-profile-for-oauth-20) to obtain all the required constants for OAuth 2.0 JWT Profile configuration, which will be used as the *GOOGLE_ISS*, *GOOGLE_SECRET_KEY* environment variable.

## Register the Push Endpoint
- Assign a device that will be used for tests execution to a Device Group.
- Copy your device’s agent URL from the Electric Imp IDE.
- Go to the [Google Search Console](https://www.google.com/webmasters/tools), enter your agent URL and click ‘Add a property’:
![Search console add property](http://imgur.com/ZFpLQHY.png)
- Download the suggested HTML verification file:
![Search console download](http://imgur.com/AEe7O69.png)
- Add the following code to your agent. Make sure you enter the *GOOGLE_SITE_VERIFICATION* value with the downloaded HTML verification file’s contents, and then click ‘Build and Run’.
```squirrel
const GOOGLE_SITE_VERIFICATION = "...";
http.onrequest(function (request, response) {
    response.send(200, GOOGLE_SITE_VERIFICATION);
});
```
![Imp verification code](http://imgur.com/HzSt05P.png)
- In the [Google Search Console](https://www.google.com/webmasters/tools), click on the link ‘Confirm successful upload by visiting ... in your browser’ and then click ‘Verify’:
![Search console steps](http://imgur.com/l8z6WvP.png)
You should receive a success message like “Congratulations, you have successfully verified your ownership of ...”
- Go to the [Google Cloud Console](https://console.cloud.google.com).
- Select your project.
- In the hamburger menu choose ‘APIs & Services’, then select ‘Credentials’:
![Credentials](http://imgur.com/ewnRN6i.png)
- Select ‘Domain verification’ and click ‘Add domain’:
![Domain verification](http://imgur.com/XfQwV1f.png)
- Enter your agent URL and click ‘Add domain’:
![Add domain](http://imgur.com/SmNDmsf.png)

## Set Environment Variables

- Set the mandatory environment variables (*GOOGLE_PROJECT_ID*, *GOOGLE_ISS*, *GOOGLE_SECRET_KEY*, *AWS_LAMBDA_REGION*, *AWS_ACCESS_KEY_ID*, *AWS_SECRET_ACCESS_KEY*) to the values you retrieved and saved in the previous steps.
- If needed, set optional environment variables
    - *GITHUB_USER* / *GITHUB_TOKEN* - a GitHub account username / password or personal access token. You need to specify them when you got `GitHub rate limit reached` error.
- For integration with [Travis](https://travis-ci.org) set *EI_LOGIN_KEY* environment variable to the valid impCentral login key.

## Run Tests

- See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.
- Run [impt](https://github.com/electricimp/imp-central-impt) commands from the root directory of the lib. It contains a [default test configuration file](../.impt.test) which should be updated by *impt* commands for your testing environment (at least the Device Group must be updated).
