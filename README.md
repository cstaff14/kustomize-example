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
cd base/mysql
oc create -f deployment.yaml
oc apply -f pvc.yaml
oc create -f service.yaml
```

## After an edit you can rerun apply to update the resource
NOTE: you can use any editor you like; vim, emacs, code, etc.
<!-- edit yaml file on prev resource and apply (TODO:verify if this can also be done with create)-->
```
gedit deployment.yaml
oc apply -f deployment.yaml
```

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
```
castaffo@castaffo-mac kustomize-example % tree                   
.
├── README.md
├── base
│   ├── kustomize.yaml
│   ├── mysql
│   │   ├── deployment.yaml
│   │   ├── pvc.yaml
│   │   └── service.yaml
│   ├── mysql-whole-manifest.yaml
│   ├── wordpress
│   │   ├── deployment.yaml
│   │   ├── pvc.yaml
│   │   └── service.yaml
│   └── wordpress-whole-manifest.yaml
└── overlays
    ├── prod
    │   ├── kustomization.yaml
    │   └── wordpress-deployment-patches.yaml
    └── stg
        └── kustomization.yaml
```
NOTE: `wordpress-whole-manifest.yaml` and `mysql-whole-manifest.yaml` are not used in the kustomize structure and are only to demonstrate manifests in the secion above

## kustomization files
These contain references to resources, patches applied to those resources and define generators you want kustomize to create. resources can be individual files or the relative path to a directory that also contains a `kustomization.yaml`. 

### base/app/kustomization.yaml
- resources are the yaml manifest for each app
- lowest level must have only individual file names
- referenced by `base/kustomization.yaml`
```
kind: Kustomization
resources:
  - deployment.yaml
  - pvc.yaml
  - service.yaml
```
### base/kustomization.yaml
- Base layer kustomization definition
- Referenced by overlay kustomizations
  - overlays use the resources described here as well
```
kind: Kustomization
resources: # directories (or single files) to pull manifests from
  - wordpress
  - mysql

secretGenerator: # an option to use kustomize to generate a secret
  - name: mysql-pass
    options:
      disableNameSuffixHash: true
    literals:
      - password=t3stp@55
```
### overlays/env/kustomization.yaml
- Imports all files from the base directory
- Defines patches to taylor the base resources specifically for this environment

```
kind: Kustomization
resources:
  - ../../base # directory that also has a kustomization.yaml to import
patches:
  - target: # resource we want to patch
      labelSelector: app=wordpress # all resources with this label
    path: wordpress-prod-ns-patch.yaml # patch file
  - target:
      kind: Route
      name: wordpress
    path: patch-hostname.yaml
  - target:
      group: apps
      version: v1
      kind: Deployment # only deployments named wordpress
      name: wordpress
    path: patch-replicas.yaml
```

## Resources
- can be generated by kustomize using a `secretGenerator` or `configMapGenerator`
```
secretGenerator:
  - name: mysql-pass
    options:
      disableNameSuffixHash: true
    literals:
      - password=t3stp@55
```
- or composed by kustomize by referencing a yaml manifest or directory of yaml manifests
```
resources:
  - wordpress
  - mysql
```

## Bases and Overlays
- A *base* is a directory with a `kustomization.yaml`, which contains a set of resources and associated customization

TODO: add base kustomization

- An *overlay* is a directory with a `kustomization.yaml` that refers to other kustomization directories as its bases

TODO: add overlay kustomization

- A *base* has no knowledge of an *overlay* and can be used in multiple overlays. An overlay may have multiple bases and it composes all resources from bases and may also have customization on top of them
## Patches
- yaml paths
- can think of them like a directory structure
TODO: add yaml structure and liken it to a file tree
- TODO: include changing a container name to demonstrate the location

## Demo

### Creating Environments for stage and production

### Create projects for stage and production
```
oc new-project wordpress-stg
oc new-project wordpress-prod
```