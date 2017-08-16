## Google Cloud account configuration
- Login at [Google Cloud Console](https://console.cloud.google.com) in your web browser.
- If you have an existing project that you want to work with, skip this step. 
Otherwise click "Select a project" link and click "+" in the opened window.
![Project create](http://imgur.com/2FbH9S6.png)
Enter "Project name" and click "Create".
- Click "Select a project" link and choose your project.
Copy ID of your project, the value will be used as PROJECT_ID configuration constant value.
![Project select](http://imgur.com/PR9U25p.png)
- In the left side menu choose "Pub/Sub" and click "Enable API".
![PubSub enable](http://imgur.com/81zNGg1.png)
- Follow the instructions from [JWT Profile for OAuth 2.0](https://github.com/electricimp/OAuth-2.0/tree/master/examples#jwt-profile-for-oauth-20) to obtain all required constants for OAuth 2.0 JWT Profile configuration.

## GooglePubSub examples configuration
- Set the example code configuration constants with values retrieved on the previous steps.
![Examples config](http://imgur.com/G0Mw9uv.png)

## Google Cloud account configuration for PushSubscriber example
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