# Springboot Helloworld Dispatch Demo
This application is used to Demo CI/CD concepts using D2iQ Dispatch on Konvoy. 

## 1. Prerequisites

### 1.1 Fork this repo along with the accompanying GitOps repo to your account:
1. https://github.com/cmays20/springboot-helloworld-dispatch
1. https://github.com/cmays20/springboot-helloworld-dispatch-gitops

Clone these repos to your local workstation as you will need to edit some of the files.

### 1.2 Update the Dispatchfile:
There are variables at the top of the Dispatchfile that are user specific:
1. `docker_user` should match your username for hub.docker.com.
1. `github_user` should match your GitHub username and the one you used to fork this repo.
1. `sonar_url` should be set to the fully qualified url where you are hosting sonar

### 1.3 Add GITHUB_USERNAME and GITHUB_TOKEN to your environment variables
To make this step easier, I have just added the following lines to my `.bash_profile`:
```bash
export GITHUB_USERNAME=<YOUR GITHUB USERNAME>
export GITHUB_TOKEN=<YOUR GITHUB TOKEN>
```
You don't need to do it this way, of course you can just run these export commands every time if you wish. 

The Dispatch documentation covers creating a token and which permissions it needs: https://docs.d2iq.com/ksphere/dispatch/1.2/tutorials/ci_tutorials/credentials/.
Click on the GitHub black text to expand the instructions under step 1 of "Setting up Github credentials".

## 2. Demo Setup

### 2.1 Setup Script
An easy installation script has been created: `bin/install-springboot-cicd.sh`.

To use the script, run it from the root directory of your git clone for the springboot application:

```bash
bin/install-springboot-cicd.sh
```
NOTE: You will see some failure lines in the output of the script. 
This is by design as the script first checks to see if the Dispatch service account and credentials have been created yet.
You can ignore these if you are running the script for the first time on your cluster.

When the script completes, it will output the URL for the helloworld application.

## 3. Performing the Demo
Show the current state of the application.  Make sure you reset your repo so it starts at "Hello World".

### 3.1 Developer - Running a CI build (Patch Branch)
The first step will be to run a CI build on a branch that is NOT master. This will cause the pipeline to just compile and test the code.
We can show how chat ops works as well when we do comments in the Pull Request.

#### 3.1.1 Create a new branch
You can do this in whatever way you feel comfortable (IDE, Github itself or the command line).

#### 3.1.2 Make a change and commit/push
Update the file `src/resources/templates/index.html`

When you start it will say "Hello World", change it to something like "Hello World with Dispatch!!!".
Then, commit the change and push the new branch up to Github. This will trigger the webhook to fire and tell Tekton to start the build.

#### 3.1.3 Show the build in Tekton
You can get to Tekton from the Dispatch Dashboard. Click on Pipeline Runs in Tekton to see the run for this build. 
You will see a Generate Pipeline job run first.  This job compiles the starlark file to Tekton yaml.

#### 3.1.4 Create a Pull Request (PR)
Take care when creating the PR that you do it in your fork only. It should be a PR from your new branch to your master branch. 
By default, Github will try to create a PR to the Master repository in mesosphere account instead of your own.

#### 3.1.5 Show that the PR must pass the checks
The build will need to succeed to get the green check mark. This means if a test failed, the person doing the code review would be able to raise a flag.

#### 3.1.6 Demo the Chatops ability
Type a comment in the PR that has the following text only `/sonar`.  This will tell the pipeline to run a sonar scan of the source code.
Go back to Tekton (a new check should pop up in the PR that you can click) and show that a sonar scan is running. 
You can show how the pipeline file is managing all this at this time. Its a good spot to start explaining how everything is working. 
When the scan completes, you can go into your sonar server and show the results of the scan.

#### 3.1.7 Merge the PR to master
This will finish the testing process and start the production build.  
You can show how the Dispatchfile has been programmed to do a different build when the branch name is master.

### 3.2 Developer - Running a production CI build (Master Branch)
This build will have started at the end of the previous step when you merged the PR.
Any push to the master branch will cause this build to occur.

### 3.2.1 Show the new build in Tekton
Show that it is following a new set of pipeline steps all governed by the Dispatchfile.
Explain that it compiles the code, builds a jar file, builds a docker image and creates a PR on the gitops repository.

### 3.3 Operator - Show the new PR on the GitOps Repository
This is a good time to show the GitOps Repository and explain that it is just Kubernetes yaml.

#### 3.3.1 Show what changed in the configuration
Click on the PR and click the compare tab to show what changed. Explain that the SHA of the Docker Image is all that was updated.

#### 3.3.2 Merge the PR
Merge the PR and navigate to the Argo GUI. Show that Argo responds to the update. 
To get a quicker response, hit the refresh button in the Argo GUI. A Canary deployment will come online in a minute or so.
The time for the whole canary progression is about 4 minutes.  So move fast through these steps. Practice the timing.

#### 3.3.3 Bring up the Kiali Dashboard
Explain that Kiali is the Dashboard for Istio. 
You can navigate to the Virtual Service for Hello World `Istio Config -> hello-world-dispatch`.
This will show the weights of the traffic to the primary and the canary.  
You can explain that the canary will start with 25% of the traffic and progress to 50% after 1 minute if there aren't any errors.
Explain that if errors did occur, that flagger would detect this using prometheus and revert the traffic back to the primary.

#### 3.3.4 Show how this all works in the canary.yaml file
Explain that flagger is following the rules specified in this file. That it can be customized by the operators to do what they need it to.
Flagger makes the programming of Istio simple so that we can take advantage of Canary Deployments with ease.
It is also fully automated and doesn't require any human intervention.

#### 3.3.5 Refresh the application
Refresh the application multiple times (just keep hitting F5) to show that the new version is coming up about 25% at first and then more when it goes to 50%.

#### 3.3.6 Show in Kiali that the deployment is progressing
Refresh Kiali to show that it is now at 50%

#### 3.3.7 Show the final stages in Argo
After running successfully at 50% for a minute with no errors, the primary application will be updated to the new docker image in a rolling fashion.
Once it comes back online, the traffic will flip back to the primary at 100%.  The canary will then be destroyed.
This is all visible in Argo.  I usually use this time to chat up the customer to see what questions they have.

### 3.4 SRE - Installation and upkeep of Dispatch
At the end is when you can talk about how easy it is to install with Konvoy and how there is nothing to manage.
It is also the time to talk about Observability.

#### 3.4.1 Show the logs for the application in Elastic Search

#### 3.4.2 Show the metrics for the application in Prometheus