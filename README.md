cicd
====

Misc. continuous integration and delivery scripts for the Barbican project.


This repository stores scripts used for project Barbican's CI/CD process, which is [further detailed here](https://one.rackspace.com/display/CIT/Cloudkeep+CI+-+Workflow+-+Dev).

This repository contains the following files:

jenkins_side_scripts/ - These run on the Jenkins box:
* barbican_build_1.sh - The first script run during the initial Jenkins job, kicked off when code is committed to Barbican.
* barbican_build_2.sh - The second script run during the intial Jenkins job, that does many things: 
   * Creates a release version and tags the repo with this version, makes a release tarball, pushes the tarball to the build box, forces the build box to make a debian package from tarball and install in its repo (see `addtorepo.sh` below), forces the test node to update to the latest release version, verifies this version is retrieved

build_box_scripts/ - These run on the build box:
* addtorepo.sh - Kicked off by the Jenkins `barbican_build_2.sh` script above. Builds the debian package, pushes into this box's debian repository

