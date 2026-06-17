# Apple App Site Association (AASA) for iOS Passkeys

iOS WebAuthn requires the iOS app to be associated with the Relying Party
domain via the **Apple App Site Association** file. Without it, registration
fails with:

> The operation couldn't be completed. Application with identifier
> `<TEAM_ID>.com.thisjowi.thisecure` isn't associated with domain
> `api.thisjowi.com`.

## How to host

1. Place `apple-app-site-association` (no `.json` extension) at:

   ```
   https://api.thisjowi.com/.well-known/apple-app-site-association
   ```

2. Serve it with `Content-Type: application/json` (or `application/octet-stream`),
   with no redirects. iOS does **not** follow redirects for AASA files.

3. The file must be reachable over HTTPS with a valid certificate.

## File content

Replace `LSKYSF7629` with the actual Apple Developer Team ID. The full
`appID` is `<TEAM_ID>.<BUNDLE_ID>`.

```json
{
  "webcredentials": {
    "apps": [
      "LSKYSF7629.com.thisjowi.thisecure"
    ]
  }
}
```

## Hosting options

### Next.js (recommended if `api.thisjowi.com` is a Next.js app)

Place the file at `public/.well-known/apple-app-site-association`. It will be
served automatically.

### Cloudflare Workers / Pages

Place the file at `dist/.well-known/apple-app-site-association` and set the
Content-Type header in the Worker, or just place it under the public
directory if using Pages.

### Nginx

```nginx
location = /.well-known/apple-app-site-association {
  add_header Content-Type application/json;
  try_files /apple-app-site-association =404;
}
```

Place `apple-app-site-association` at the web root with the JSON content above.

## Verifying

```bash
curl -I https://api.thisjowi.com/.well-known/apple-app-site-association
# Expected: HTTP/2 200, content-type: application/json

curl -s https://api.thisjowi.com/.well-known/apple-app-site-association
# Expected: {"webcredentials":{"apps":["LSKYSF7629.com.thisjowi.thisecure"]}}
```

Apple's CDN caches the AASA file for ~24h. After hosting, wait or use
[Apple's CDN cache checker](https://cdn-lists.apple.com/cdnlists/CDAV1.10/cdn-cdav1.10.json).

## When the file is not enough

If the AASA is correctly hosted but the error persists:
- Confirm the Team ID matches the Apple Developer account used to sign the
  app (the prefix in the error message — `LSKYSF7629` in the example).
- Confirm the bundle ID in `ios/Runner.xcodeproj/project.pbxproj` is
  `com.thisjowi.thisecure`.
- Uninstall the app fully and reinstall — iOS caches the association per
  install.
