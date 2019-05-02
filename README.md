# Container Builder GitHub CI connector for Google Cloud Functions
Cloud Function to use the PubSub events on the `cloud-builds` topic to update GitHub CI status.

This function is designed to work with GitHub repositories mirrored under Google Cloud Source Control named `github-${config.repoOwner}-${ghRepoName}`.
If you set this through the Container Builder build trigger UI, this will be named automatically.
 
## Deploy
[Generate a new token](https://github.com/settings/tokens) with the `repo:status` OAuth scope.

Set the following on `config` in [index.js](./index.js):
- `ciUser`
- `ciAccessToken`
- `repoOwner`

Deploy the cloud function to gcloud:
```
gcloud beta functions deploy setCIStatus --trigger-topic cloud-builds
```

## Kudos Deploy (gcb)
The above are the manual steps, the preferred approach is to deploy the function through the pipeline in Google Cloud Build.

A trigger has been manually set up to run a terraform script in order to apply changes to the Google Cloud Function every time a code change is pushed to master in this repository.

The trigger configuration includes two environment variables that are used by terraform. One of them, _GITHUB_TOKEN_, is used by the function itself and it is provided setting an enviroment variable for the function. The variables defined in the trigger are:

1. `GITHUB_TOKEN`: you can find it in the info.txt file in gocrypto-fs looking for the word `GITHUB_CI_TOKEN_GCB`
2. `PROJECT_ID`: provided by gcb.

## Alternative Kudos Deploy (local machine)

export GITHUB_CI_TOKEN_GCB=<the token> make deploy

## Behavior
CI Status **context** will be one of:
- `${projectId}/gcb: ${tags.join('/')}`
- `${projectId}/gcb: ${id.substring(0,8)}`

Use the `tags` field in your build request to name your CI.
Otherwise, it falls back to the build-GUID.

CI Status **description** will either be:
- nothing
- a join of all images to be published:
  `gcr.io/project/image:v1 gcr.io/project/image:latest`
- above all, the duration of the build:
  `3m 27s`
- possibly with the last-running build step and error status:
  `3m 27s · test failure`
