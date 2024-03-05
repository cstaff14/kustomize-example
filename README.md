# Parsing oc command help pages
You can make a help command (or any bash command) output easier to read by piping it into `fold -s` and `less` to mimic a `man` page
- `fold -s` will put seperate long lines into multiple lines
- `less` allows you to scroll and search the output like a man page
```
oc <command> <subcommand1>... --help | fold -s | less
```
<!-- show multiple iterations (oc create, then oc create secret) -->
The oc help command will bring up different pages when you add more subcommands
```
oc create --help | fold -s | less
oc create secret --help | fold -s | less
```
<!-- show navigating less with / search, mention learning to work with less -->

# Creating resources using a command
First, create a project for the manifests we're going to create
```
oc new-project wordpress-dev
oc create secret generic mysql-pass --from-literal=password=t3stp@55
```

# YAML Manifests
<!-- TODO: why yaml manifests -->
Created resources can be edited using the 
## You can create them one manifest at a time using create or apply
```
cd manifests/mysql
oc create -f deployment.yaml
oc apply -f pvc.yaml
oc create -f service.yaml
```

## After an edit you can rerun apply to update the resource
NOTE: you can use any editor you like; vim, emacs, code, etc.
`gedit deployment.yaml`
<!-- edit yaml file on prev resource and apply (TODO:verify if this can also be done with create)-->
`oc apply -f manifest.yaml`

## Defining Multiple Resources in One Manifest
Seperate resources with `---`
```
cd ../
less wordpress-whole-manifest.yaml
oc apply -f wordpress-whole-manifest.yaml
```

## Getting the yaml of an existing resource
```
oc get {resource-type}/{resource-name} -o yaml > new-manifest.yaml
```
```
oc get deployment wordpress -o yaml > wordpress-deployment.yaml
less wordpress-deployment.yaml
```

# Kustomize
<!-- TODO: why kustomize -->
<!-- TODO: can you include files that are in one env and not the other -->
## Common Problems With Maintaining Resources Solely Using Manifests
- Spinning up multiple iterations of one application is common (e.g. dev, stage, prod environments)
- Manifests can be large and may contain many configurations that are repeated across all iterations
- Copy/pasting large blocks of text can lead to mistakes and is not DRY (Do not Repeat Yourself)
- Making a change to persist across all iterations is tedious

## How Kustomize Helps
- Multiple environments can share base manifests
  - changing a base manifest persists across all environments
- Individual elements in the base manifests can be changed with patches unique to each environment
  - Applying patches only persists in one environment

## Kustomize Project Structure

## kustomize.yaml

## Resources

## Overlays

## Patches

## Demo

### Creating Environments for stage and production

### Create projects for stage and production
```
oc new-project wordpress-stg
oc new-project wordpress-prod
```