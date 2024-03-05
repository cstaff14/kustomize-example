# Parsing oc documentation
`oc <command> <subcommand1>... --help | fold -s | less`
<!-- show multiple iterations (oc create, then oc create secret) -->
<!-- show searching by keywords, mention learning to work with less -->

# Demonstrate Creating things from the command line by creating the mysql-pass secret

# YAML Manifests
`oc create -f manifest.yaml`
<!-- create new resource -->
`oc apply -f manifest.yaml`
<!-- edit yaml file on prev resource and apply -->

## Getting the yaml of an existing resource
`oc describe {resource-type}/{resource-name} -o yaml > new-manifest.yaml`

# Kustomize