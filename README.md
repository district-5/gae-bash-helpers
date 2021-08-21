Bash helpers for Google App Engine
====

This repository holds some helpful scripts for Google App Engine.

### Scripts included...

* `deploy_script.sh` - Handles the deployment of a service.
  * Edit these required variables at the top of the file:
    * `GOOGLE_CLOUD_PROJECT_ID` - The Google Cloud console project ID (for example, `my-project-id`)
    * `GCP_DEPLOY_AS_USER` - The gcloud authenticated user to execute the deployment under
    * `SERVICES_TO_CLEAN` - A list of services to clean up after deployment. This removes old versions. (for example, `default` or `default admin api` for multiple)
