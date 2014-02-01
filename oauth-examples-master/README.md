# OAuth Examples for the Asana API

Examples of how to use OAuth to access the [Asana API](http://developer.asana.com/documentation/)

## Running the examples

This repository will contain examples in several different languages and frameworks to help you get started. (Currently, we only have an example ruby app in sinatra, but more to follow.) Here are the steps you need to follow to try them out:

### Getting the code

```bash
git clone https://github.com/Asana/oauth-examples.git
cd oauth-examples/
cp .env.example .env
```

### Creating an application

Visit [the Apps tab of your Account Settings in Asana](https://app.asana.com/-/account_api) and create an application. Name it whatever you like, but be sure to enter the right URLs. For this example, let's assume you're going to run the examples on `http://localhost:5000`.  You'll want to enter the Redirect URL `http://localhost:5000/auth/asana/callback`.  After you've created it, copy the client ID and client secret - you'll need them in the next step.

### Starting the app

Edit the `.env` file and enter your client ID and secret key, which you obtained in the previous step. (You can also change the port that the process will run on, default 5000).

To actually run an app (e.g. the ruby example) you would type:

```bash
./start ruby
```

Every example will be run with the same command: `./start $SUBDIR`.

## Sign in buttons

If you want to use the same buttons we're using in the examples, feel free! They're located in the `public/` folder of this repo, or you can download them here:

![Sign in with Asana](https://github.com/Asana/oauth-examples/blob/master/public/asana-oauth-button.png?raw=true) ![Sign in with Asana](https://github.com/Asana/oauth-examples/blob/master/public/asana-oauth-button-blue.png?raw=true)

## Under the hood

So how does OAuth with Asana work exactly? What is it these examples do, and how precisely would you implement it yourself?

Obviously, a working knowledge of the OAuth 2.0 spec (we're using [Draft 31](http://tools.ietf.org/html/draft-ietf-oauth-v2-31)) is useful. If you're familiar with the spec — or intend to use an out-of-the-box OAuth 2.0 library rather than hand-coding it — all you need to know is this:

### Quick Reference

* The endpoint for user authorization is `https://app.asana.com/-/oauth_authorize`
* The endpoint for token exchange is `https://app.asana.com/-/oauth_token`
* Applications can be created from the "Apps" tab of your account settings, where you will find your Client ID and Client Secret. ([Quick Link](https://app.asana.com/-/account_api))
* We support both the Authorization Code Grant flow, and the Implicit Grant flow.
* Calls to the API made with the header `Authorization: Bearer $TOKEN` will automatically be authorized to act on behalf of the user.

Note: The currect OAuth implementation does not support scopes or other flows.

### Authorization Code Grant

To actually implement the Authorization Code Grant flow (the most typical flow for most applications), there are basically three steps:

1. Redirect a user to the authorization endpoint so that they can approve access of your app to their Asana account
2. Receive a redirect back from the authorization endpoint with a **code** embedded in the parameters
3. Exchange the code for a **token** via the token exchange endpoint

The token that you have at the end can be used to make calls to the Asana API on the authorizing user's behalf.

### Implicit Grant

The implement the Implicit Grant flow, which is suitable for in-browser web apps in JavaScript or other applications that might have difficulty making arbitrary HTTP POST requests to the token exchange endpoint, there are only two steps:

1. Redirect a user to the authorization endpoint so that they can approve access of your app to their Asana account
2. Receive a redirect back from the authorization endpoint with a **token** embedded in the *fragment* portion (the bit following the `#`) of the URL.

This token can then be used to access the API, in this case typically using JSONP.

### User Authorization Endpoint

#### Request

Your app redirects the user to `https://app.asana.com/-/oauth_authorize`, passing parameters along as a standard query string:

* `client_id` - *required* The Client ID uniquely identifies the application making the request.
* `redirect_uri` - *required* The URI to redirect to on success or error. This *must* match the Redirect URL specified in the application settings.
* `response_type` - *required* Must be one of either `code` (if using the Authorization Code Grant flow) or `token` (if using the Implicit Grant flow). Other flows are currently not supported.
* `state` - *optional* Encodes state of the app, which will be returned verbatim in the response and can be used to match the response up to a given request.

#### Response

If either the `client_id` or `redirect_uri` do not match, the user will simply see a plain-text error. Otherwise, all errors will be sent back to the `redirect_uri` specified.

The user then sees a screen giving them the opportunity to accept or reject the request for authorization. In either case, the user will be redirected back to the `redirect_uri`.

If using the `response_type=code`, your app will receive the following parameters in the query string on successful authorization:

* `code` - This is the code your app can exchange for a token
* `state` - The state parameter that was sent with the authorizing request

If using the `response_type=token`, your app will receive the following parameters in the URL fragment (the bit following the `#`):

* `token` - This is the token your app can use to make requests of the API
* `state` - The state parameter that was sent with the authorizing request

### Token Exchange Endpoint

#### Request

If your app received a code from the authorization endpoint, it can now be exchanged for a proper token, optionally including a refresh_token, which can be used to request new tokens when the current one expires without needing to redirect or reauthorize the user.

Your app makes a `POST` request to `https://app.asana.com/-/oauth_token`, passing the parameters as part of a standard form-encoded post body.

* `grant_type` - *required* Must be `authorization_code`
* `client_id` - *required* The Client ID uniquely identifies the application making the request.
* `client_secret` - *required* The Client Secret belonging to the app, found in the details pane of the developer view
* `redirect_uri` - *required* Must match the redirect_uri specified in the original request
* `code` - *required* The code you are exchanging for an auth token

Alternatively, if you are exchanging a refresh_token, the `grant_type` should be `refresh_token` and instead of sending `code=...` you would send `refresh_token=...`.

#### Response

In the response, you will receive a JSON payload with the following parameters:

* `access_token` - The token to use in future requests against the API
* `expires_in` - The number of seconds the token is valid, typically 3600 (one hour)
* `token_type` - The type of token, in our case, `bearer`
* `refresh_token` - If exchanging a code, a long-lived token that can be used to get new access tokens when old ones expire.
* `user` - A JSON object encoding a few key fields about the logged-in user, currently `id`, `name`, and `email`.

## Feedback

Please send any feedback or issues to [api-support@asana.com](mailto:api-support@asana.com).

## MIT License

All examples copyright (c) 2013 Asana, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
