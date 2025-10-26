Pai6 Full AutoDeploy Suite - Quickstart
--------------------------------------
1. Upload/unzip this package in Google Cloud Shell.
2. Run: chmod +x pai6_full_autodeploy.sh && ./pai6_full_autodeploy.sh
3. The launcher will call the internal scripts to prepare environment, build images and deploy to Cloud Run.
4. After deploy, open the frontend URL shown in logs. Access Dynamic Config Manager at /admin/config endpoint.
Notes:
- Some actions require Owner/Billing permissions (enabling APIs, creating artifact registry, domain mapping).
- Check logs/deploy.log for details.
