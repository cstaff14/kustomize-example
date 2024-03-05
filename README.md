# Parsing oc documentation
```
oc <command> <subcommand1>... --help | fold -s | less
```
<!-- show multiple iterations (oc create, then oc create secret) -->
```
oc create --help | fold -s | less
oc create secret --help | fold -s | less
```
<!-- show navigating less with / search, mention learning to work with less -->

# Creating resources using a command
First, create a project for the manifests we're going to create
`oc new-project wordpress-dev`
`oc create secret generic mysql-pass --from-literal=password=t3stp@55`

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
<!-- edit yaml file on prev resource and apply (verify if this can also be done with create)-->
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

```

# Kustomize
<!-- TODO: why kustomize -->
- Spinning up multiple iterations of one appliaction is common
- Manifests are large and will contain a lot of repeated configurations
- 
## Create projects for stg and prod

## Resources

## Overlays