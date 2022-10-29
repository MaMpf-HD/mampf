# Contributing

To ensure a smooth experience for contributions, please first open an issue about the change you wish to make or contact
an active developer in some other way before making a change.

## Braches
We have the following branches:
- *production*
- *main*
- *mampf-next*
- feature-branches (names vary)
- *experimental*

### *production*
contains the actual version deployed on [mampf](mampf.mathi.uni-heidelberg.de).

### *main*
is usually equal to *production*. Hotfixes are tested here before being merged to *production*.

### *mampf-next*
is the next intended version for mampf. This version is automatically deployed on
[mampf-dev](mampf-dev.mathi.uni-heidelberg.de). Features should be developed in feature branches and merged here.

### feature branches
Collaborators may create a branch for each improvement they would like to integrate in *mampf-next*. If you do not have
collaborator access yet, feel free to instead fork this repository and open a pull request targeted on the *mampf-next*
branch.

### *experimental*
is used as a playground and for test deployments. Do **not** put important work here. This branch is intended to be
force-pushed by any collaborator. If you ever want to deploy a version in a production-like environment, feel free to
do

> git checkout experimental
>
> git reset --hard <version>
>
> git push -f

If you are not a collaborator, feel free to open a pull-request on experimental with a note, that you are aware of this
policy and would just like to try out a change.
