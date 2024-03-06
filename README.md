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
- k8s resources can be created or edited by using yaml files stored on your local machine
- This allows you to edit k8s resources using whatever text editor you see fit
- These manifests can be stored in a git repo to be shared across teams and leverage GitOps
## You can create them one manifest at a time using `oc create`
```
cd base/mysql
oc create -f deployment.yaml
oc create -f pvc.yaml
oc create -f service.yaml
```

## After an edit you can run `oc apply` to update the resource
NOTE: you can use any editor you like; vim, emacs, code, etc.
<!-- edit yaml file on prev resource and apply -->
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
├── base
│   ├── kustomization.yaml
│   ├── mysql
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   ├── pvc.yaml
│   │   └── service.yaml
│   ├── mysql-whole-manifest.yaml
│   ├── wordpress
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml
│   │   ├── pvc.yaml
│   │   ├── route.yaml
│   │   └── service.yaml
│   └── wordpress-whole-manifest.yaml
└── overlays
    ├── prod
    │   ├── kustomization.yaml
    │   ├── patch-hostname.yaml
    │   ├── patch-replicas.yaml
    │   └── wordpress-prod-ns-patch.yaml
    └── stg
        ├── kustomization.yaml
        ├── patch-hostname.yaml
        ├── patch-podname.yaml
        └── wordpress-stg-ns-patch.yaml
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
- An *overlay* is a directory with a `kustomization.yaml` that refers to other kustomization directories as its bases
- A *base* has no knowledge of an *overlay* and can be used in multiple overlays. An overlay may have multiple bases and it composes all resources from bases and may also have customization on top of them
## Patches
- These are yaml manifests that describe the changes to be made for each environment
- can be done by passing in a regular yaml manifest where new and different values from the source material will be applied
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 2
```
- Or we can use a patch action that points to a yaml path for the object that describes the action and new value
```
- op: replace # action (replace or add)
  path: /spec/host # yaml path to the resource we want to change
  value: # value we want to use for patching
    wordpress-prod.apps.ocp4.example.com
```
- in the case where there are multiple resources in the yaml path we can target one by using its sequential value (starting from 0). The following will apply the change to the first container definition
```
- op: replace
  path: /spec/template/spec/containers/0/name
  value: wordpress-stg
```
## Demo
### Prod
Create a project for Prod resources
```
oc new-project wordpress-prod
```
Apply prod kustomizations
```
oc apply -k overlays/prod
```
Then view all newly created resources to see that the wordpress deployment has two replicas and the route's hostname has changed
```
$ oc get all
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
NAME                                  READY   STATUS    RESTARTS       AGE
pod/wordpress-75bc7cc547-h79cv        1/1     Running   1 (167m ago)   171m
pod/wordpress-75bc7cc547-zkzmv        1/1     Running   0              171m
pod/wordpress-mysql-b759dbb45-btcmb   1/1     Running   0              171m

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/wordpress         ClusterIP   172.30.34.214   <none>        8080/TCP   172m
service/wordpress-mysql   ClusterIP   None            <none>        3306/TCP   171m

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/wordpress         2/2     2            2           172m
deployment.apps/wordpress-mysql   1/1     1            1           172m

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/wordpress-75bc7cc547        2         2         2       172m
replicaset.apps/wordpress-mysql-b759dbb45   1         1         1       172m

NAME                                 HOST/PORT                              PATH   SERVICES    PORT   TERMINATION   WILDCARD
route.route.openshift.io/wordpress   wordpress-prod.apps.ocp4.example.com          wordpress   8080                 None
```
### Stage
Create a project for Stage resources
```
oc new-project wordpress-stg
```
Apply  kustomizations and view new resources
```
oc apply -k overlays/stg

oc get all
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
NAME                                  READY   STATUS    RESTARTS        AGE
pod/wordpress-677d75d976-rht5g        1/1     Running   1 (7m16s ago)   8m6s
pod/wordpress-mysql-b759dbb45-fmjgd   1/1     Running   0               8m6s

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/wordpress         ClusterIP   172.30.244.230   <none>        8080/TCP   8m6s
service/wordpress-mysql   ClusterIP   None             <none>        3306/TCP   8m6s

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/wordpress         1/1     1            1           8m6s
deployment.apps/wordpress-mysql   1/1     1            1           8m6s

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/wordpress-677d75d976        1         1         1       8m6s
replicaset.apps/wordpress-mysql-b759dbb45   1         1         1       8m6s

NAME                                 HOST/PORT                             PATH   SERVICES    PORT   TERMINATION   WILDCARD
route.route.openshift.io/wordpress   wordpress-stg.apps.ocp4.example.com          wordpress   8080                 None
```
Then, to see the new name for the wordpress container
```
$ oc describe deployment wordpress
Name:               wordpress
Namespace:          wordpress-stg
CreationTimestamp:  Wed, 06 Mar 2024 13:31:39 -0500
Labels:             app=wordpress
Annotations:        deployment.kubernetes.io/revision: 1
Selector:           app=wordpress,tier=frontend
Replicas:           1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:       Recreate
MinReadySeconds:    0
Pod Template:
  Labels:  app=wordpress
           tier=frontend
  Containers:
   wordpress-stg:
    Image:      castaffo/wordpress:6.2.2-apache
    Port:       8080/TCP
    Host Port:  0/TCP
    Environment:
      WORDPRESS_DB_HOST:      wordpress-mysql
      WORDPRESS_DB_PASSWORD:  <set to the key 'password' in secret 'mysql-pass'>  Optional: false
      WORDPRESS_DB_USER:      wordpress
    Mounts:
      /var/www/html from wordpress-persistent-storage (rw)
  Volumes:
   wordpress-persistent-storage:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  wp-pv-claim
    ReadOnly:   false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   wordpress-677d75d976 (1/1 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  8m42s  deployment-controller  Scaled up replica set wordpress-677d75d976 to 1
```
