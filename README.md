# DevSecOps - Lab

This is the DevSecOps Lab created to visualize the basic DevSecOps activities

# What to expect

In this lab, we are going to deploy a new environment step by step in order to be able to test and experiment with different DevSecOps Tools.

# Requirements

This lab was created with Windows 11 and Docker Desktop version 23.0.5, build bc4487a.

## Notes

In order to access to applications with their aliases, you would need to create the Name records under your hosts file located on C:\Windows\System32\drivers\etc\hosts

## Phase 2 "Building DSO Image and running Hadolint Scan"

In this phase, we are going to create a docker image that contains the DevSecOps tools in order to allow to achieve the scans and checks we want to implement into an application pipeline.

1. git switch 01-building-dso-image
2. Go to http://jenkins.demo.local:8080 on the web browser of your host computer.
3. Go to Plugin Manager and install Docker plugin and Docker Pipeline plugins.
4. Create the multibranch pipeline, and add the Github corresponding to dso-tools as source.

## Phase 3 "Pushing DSO Image to Github Packages (Container Registry)"

In this phase, we are going to push the DSO image we create into a Docker Registry. In this Demo, we are going to use Github packages as example, but you can push it to your desired Docker Registry.

1. git switch 02-pushing-to-registry
2. Create the Github Personal Access token (Classic) with Write, Read and Delete packages permissions.
3. Go to Jenkins, Credentials, and create a global credential with ID "github_token" (Name needed to match Jenkins file) and password would be the token created. Username and Description is for your own management.
4. The Jenkins file now contains the "Push to Registry" Stage in which we are tagging and pushing the image to Github packages.

## Phase 4 "Scanning the DSO Image with Trivy"

1. git switch 03-scanning-image-trivy
2. Install HTMLPublisher plugin in jenkins.

## Excercise:

1. Try to order/clean the Trivy report. This means to maybe just leave the vulnerabilities with the severity you want, and see if you can order by same thing.