#!/bin/bash

set -e
set -v

TOP_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P )
cd $TOP_DIR

# build the dax generator
export CLASSPATH=.:`pegasus-config --classpath`
javac --release 8 BlackDiamondDAX.java

# generate the dax
java BlackDiamondDAX /usr blackdiamond.yml

# create the site catalog
cat >sites.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<sitecatalog xmlns="http://pegasus.isi.edu/schema/sitecatalog" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pegasus.isi.edu/schema/sitecatalog http://pegasus.isi.edu/schema/sc-4.0.xsd" version="4.0">
<site  handle="condorpool" arch="x86_64" os="LINUX" osrelease="" osversion="" glibc="">
	<profile namespace="env" key="PEGASUS_HOME" >/usr</profile>
	<profile namespace="condor" key="universe" >vanilla</profile>
	<profile namespace="pegasus" key="style" >condor</profile>
</site>
<site  handle="local" arch="x86_64" os="LINUX" osrelease="" osversion="7" glibc="">
	<directory  path="$HOME/workflows/scratch" type="shared-scratch" free-size="" total-size="">
		<file-server  operation="all" url="file://$HOME/workflows/scratch">
		</file-server>
	</directory>
	<directory  path="$HOME/workflows/outputs" type="local-storage" free-size="" total-size="">
		<file-server  operation="all" url="file://$HOME/workflows/outputs">
		</file-server>
	</directory>
</site>
</sitecatalog>
EOF

# plan the workflow
pegasus-plan \
	--output-sites local \
	--conf pegasusrc \
	blackdiamond.yml
