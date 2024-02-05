#!/bin/bash
 
# Add web url to frontend app registration.
 
if [ -n "${AZURE_FRONTEND_APPLICATION_ID}" ]; then
  OBJECT_ID=$(az ad app show --id ${AZURE_FRONTEND_APPLICATION_ID} | jq -r '.id')
  BODY="{spa:{redirectUris:['${REACT_APP_WEB_BASE_URL}']}}"
  az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/$OBJECT_ID" --headers "Content-Type=application/json" --body $BODY
fi