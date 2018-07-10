.PHONY: deploy
deploy:
	sed -i .bak 's/personalAccessToken/${GITHUB_CI_TOKEN_GCB}/g' index.js
	gcloud beta functions deploy setCIStatus --trigger-topic cloud-builds


