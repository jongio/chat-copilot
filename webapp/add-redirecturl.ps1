<#
.SYNOPSIS
Add web url to frontend app registration.
#>
if ($env:AZURE_FRONTEND_APPLICATION_ID -ne '') {
  $objectId = (az ad app show --id $env:AZURE_FRONTEND_APPLICATION_ID | ConvertFrom-Json).id
  $body = "{spa:{redirectUris: [" + "'$env:REACT_APP_WEB_BASE_URL'" + "]}}"
  az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/$objectId" --headers 'Content-Type=application/json' --body $body
}