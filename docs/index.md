
# Litmus Inline - Developer integration guide

## Overview

Litmus Inline allows you to add select parts of the Litmus experience as a step within your email application in just a few lines of client-side JavaScript.

## Example integration

- [Reference integration source](https://github.com/litmus/litmus-inline-example)
- Reference integration live instances:
  - [configured to allow all Litmus plan types](https://litmus-inline-all-plan.herokuapp.com)
  - [configured for Enterprise customers](https://litmus-inline-enterprise.herokuapp.com)
  - [configured for Enterprise customers, but no anonymous testing](https://litmus-inline-no-anon-access.herokuapp.com)

## Setup

Embed our SDK's integration script in your editor page:
```html
<script src='https://litmus.com/inline/sdk-1.0.js'></script>
```

Then setup the integration:
```js
Litmus.setup({
  publishableKey:    "<publishable-key>",  // provided by Litmus, prefixed pk_
  sessionSigningUri: "urn:litmus:inline:skip-signing" // see session signing below
});
```

Identify your end user and what project (or campaign) they're working on:
```js
Litmus.identify({
  user:    "<anonymised-user-hash>",
  account: "<anonymised-account-hash>", // optional
  project: "<anonymised-project-hash>"
});
```

The identification details can be hashed to maintain anonymity until the user chooses to sign up or login to Litmus. The only requirement for these strings is that a user (or account/project) that's unique to your system gets a string that is also unique. This means you can just provide integer ids if you prefer.

Next, describe how to the obtain the email from the page context by providing callback functions returning the desired data, which will be called each time a new Litmus test is requested:

```js
Litmus.emailSubjectFrom(function () { return "foo"; });
Litmus.emailHtmlFrom(function () { return "bar"; });
Litmus.emailPlainTextFrom(function () { return "baz"; }); //optional
```

Add a div the SDK can target in to your UI with id `litmus-container`:

```html
<div id="litmus-container"></div>
```

When the user reaches a stage in your application where you wish to show Litmus Inline call:

```js
Litmus.open(Litmus.PREVIEWS)
```

This creates a new iFrame within the container, sends on the identification information and opens the integration with the requested Litmus features, in this case just "Previews".

Each time the user returns to the Litmus step in your application, call `Litmus.open` once more.

## Pseudo-anonymity and user hand off

From a user perspective there are two distinct phases of Litmus Inline usage:

- **pseudo-anonymous**

  A user authenticated with your app is uniquely identified to Litmus, they receive a limited free user experience. In the case of the Previews product this means a fixed monthly allowance of previews they can run.

  If your integration does not require this functionality, it can be disabled by discussing with your point of contact at Litmus. This isn't a feature that can be disabled via the SDK.

- **authenticated with Litmus**

  A user logs in or signs up for a paid Litmus plan and associates their account in your application with their account in Litmus. They receive a more complete user experience and are able to lean on more features and settings available in the main Litmus application.

## Embedding

You must embed the script directly from litmus.com:

```html
<script src='https://litmus.com/inline/sdk-1.0.js'></script>
```

**Do not self host a static version of this** – the contents of the script changes over time.

The "1.0" versioning here reflects SDK contract compatability, not a file version.

## HTTPS

The SDK and all its resources on litmus.com are served securely via HTTPS/TLS. We similarly require that the parent page within your application where the SDK is utilised to be secured with HTTPS/TLS.

## Layout, frame sizing considerations

The injected frame has a **minimum width of 1280px**, it is best to arrange your layout to minimise page content to the left or right of the frame when Litmus Inline is visible.

The frame dynamically resizes its height rather than showing its own scroll bar to provide more seamless integration with your page. Typically this ranges between approximately 700px - 2000px, but varies based on the content in the frame and on the width of the frame. You should anticipate the frame being taller than the browser viewport and so vertical scrolling may be required.

Due to the requirements mentioned above and because of the nature of the user interface within the frame it's inadvisable to locate the frame within a modal window overlaying your application.

The SDK assumes the email source will not alter while the Litmus frame is visible. For this reason **please ensure your editor is hidden when Litmus Inline is open**.

## Supported browsers

We aim for the same browser support for Litmus Inline as the main Litmus application. There may be cases where this isn't possible due to differences in support for some of the more specialised features we rely on to support frame interactions.

In general we aim to support the current and previous stable desktop releases of Chrome, Safari and Firefox. We do similar with Microsoft's browsers, which at the time of writing means Edge 16, IE11, IE10. Litmus Inline and the main Litmus application do not support mobile browsers, though some features may work.


## Inline Pseudo-anonymous Session Signing

### What's the problem?

- We allow a monthly allowance of free previews to users with no Litmus account
- These users must already be authenticated with your application
- To allow this functionality, Litmus needs to:
  - receive the data describing the user's email for testing
  - manage each user's usage allowance
- To achieve this there's a minimum of information we require:
  - unique identification of your user
  - verification that the user has a legimate active session in your product

### How do we solve this?

- You're provided a secret key (prefixed `sk_`) that is held server side and never shared.
- You provide a simple serverside HTTP endpoint that uses this key to sign a JWT that proves the user's active session in your application.
  - for more information about JSON Web Token standard, see:
    - IETF RFC: https://tools.ietf.org/html/rfc7519
    - https://jwt.io/ for libraries and interactive decoder

### Usage

If we have

```
# provided by litmus
publishableKey = "pk_123456"
secretKey      = "sk_654321"

# hashed values generated by you using salted hash
user           = "U13579XYZ"
```

then at SDK setup

```js
Litmus.setup({
  publishableKey: "pk_123456",
  sessionSigningUri: "/sign-session-jwt"
})
```

The SDK will then request a signed JWT from the server
 - on each Litmus.identify call
 - when the JWT becomes stale

HTTP request made by the SDK, in the context of your application (ie with any session cookies, if you require custom headers, [see below](#custom-headers)):

```
POST https://your-esp.com/sign-session-jwt
{
  "publishableKey": "pk_123456",
  "user": "U13579XYZ",
}
```

Serverside, you must:
 - check the user matches the current session
 - optionally check the publishableKey supplied matches the one provided to you

On failure: respond 403 Forbidden

On success:
 - add an issued at timestamp to the JSON provided, `iat` the current time as a unix timestamp
 - construct a standard JWT, using the HS256 signing algorithm, composed of three parts: header, payload, and signature.
 - respond with 200 OK status, and encoded JWT as response body

```
header:
{
  "alg": "HS256",
  "typ": "JWT"
}

payload: (the JSON provided, with the added `iat` field):

{
  "publishableKey": "pk_123456",
  "user": "U13579XYZ",
  "iat": 1234567890
}

signature:

HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  "sk_654321"
)
```

Create the fully encoded JWT:

```
base64UrlEncode(header) + "." +
  base64UrlEncode(payload) + "." +
  base64UrlEncode(signature)
```

Which should produce the following:

```
eyJhbGciOiJIUzI1NiJ9.eyJwdWJsaXNoYWJsZUtleSI6InBrXzEyMzQ1NiIsInVzZXIiOiJVMTM1NzlYWVoiLCJpYXQiOjEyMzQ1Njc4OTB9.2vsYUoj0jAnZkeL2PK_bdBg4N9WpWjCh7nEIX_mY1D4
```

### Real world implementation

The session signing endpoint can be implemented in only a few lines if we lean on a JWT library:

```ruby
post '/sign-session-jwt' do
  @payload = JSON.parse(request.body.read)
                 .merge('iat' => Time.now.to_i)

  halt 403 unless jwt_user_matches_session_user?

  JWT.encode(@payload, ENV['SECRET_KEY'], 'HS256')
end

```
### Optional JWT payload fields

The JWT payload **may** include the additional fields `project` and `account`.

If you wish **you may** perform additional verification that the user has access appropriate to these items.

You **must** ensure all the fields supplied are returned in the response payload in addition to the `iat` field.

eg from SDK you might receive
```
POST https://your-esp.com/sign-session-jwt
{
  "publishableKey": "pk_123456",
  "user": "U13579XYZ",
  "project": "ABC123",
  "account": "DEF456"
}
```

and the expected JWT payload would be

```
{
  "publishableKey": "pk_123456",
  "user": "U13579XYZ",
  "project": "ABC123",
  "account": "DEF456",
  "iat": 1234567890
}

```

### Custom headers

If the request to your server for session signing requires additional headers, in particular if you manually send authentication tokens rather than using session cookies, you may pass an optional parameter to `Litmus.setup` – `sessionSigningHeaders`.

The parameter value is expected to be either a JavaScript object, or a callback returning a JavaScript object which will be run before each request to your server. Each key/value pair in the object is applied as a header.

eg

```
Litmus.setup({
  // after required config...
  sessionSigningHeaders: headersCallback
});

function headersCallback() {
  return { "Authorization": "Bearer " + yourSessionJwt() }
}
```

### Development mode

To get started quickly you may disable session signing in a development mode integration by providing the URN `urn:litmus:inline:skip-signing` as the `sessionSigningUri` provided to `Litmus.setup`, ie:

```
Litmus.setup({
  publishableKey: "pk_123456",
  sessionSigningUri: "urn:litmus:inline:skip-signing"
})
```

## Javascript errors

We endeavour to ensure the SDK, or any other supplied JavaScript is tested and fault free. We do not anticipate you should encounter any JavaScript errors outside those that are intentionally generated to flag integration problems.

We've had report of an error in the past that was unrelated to the SDK, instead caused by a third-party script used by Litmus.com directly within the frame. Litmus.com uses a number of third party services for purposes such as account protection and analytics which may encounter outages / environmental issues that are outside our control. The SDK never incorporates third-party JavaScript within the context of your application, so in the unlikely event of encountering an issue, it will be contained within the context of iframe injected by the SDK, and should not impact the parent window.

However, if you encounter any JavaScript issues that are unexpected, we would appreciate being notified of such an occurrence, along with browser and operating system details so we can investigate.

## Roadmap, future features

Although the beta focusses on Inbox Previews, our intention is that, over time, a number of other key Litmus product features will be made available to partners, for use within the Litmus Inline experience. These additional features will not automatically be enabled. Instead, they will be enabled by mutual agreement with each integrator.

Future features may require additional integration work. Typically, this will be provision of additional data required by other test types.
