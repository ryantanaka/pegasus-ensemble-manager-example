#!/usr/bin/env python3
import logging
from pathlib import Path

from Pegasus.api import *

logging.basicConfig(level=logging.INFO)

# --- working directory setup --------------------------------------------------
WORK_DIR = Path.home() / "workflows"
WORK_DIR.mkdir(exist_ok=True)

TOP_DIR = Path(__file__).parent.resolve()

# --- properties setup ---------------------------------------------------------
props = Properties()
props["pegasus.mode"] = "development"

# specify abs path to catalogs
sc_file = str(TOP_DIR / "sites.yml")
tc_file = str(TOP_DIR / "transformations.yml")
props_file = str(TOP_DIR / "pegasus.properties")

props["pegasus.catalog.site.file"] = sc_file
props["pegasus.catalog.transformation.file"] = tc_file
props.write(props_file)

# --- output dir setup ---------------------------------------------------------
sc = SiteCatalog()
# override default local site
local_site = Site(name="local")
local_shared_scratch = Directory(Directory.SHARED_SCRATCH, path=WORK_DIR / "scratch") \
                        .add_file_servers(
                            FileServer(
                                url="file://" + str(WORK_DIR / "scratch"), 
                                operation_type=Operation.ALL
                            )
                        )

local_local_storage = Directory(Directory.LOCAL_STORAGE, path=WORK_DIR / "outputs/workflow-1") \
                        .add_file_servers(FileServer(
                                url="file://" + str(WORK_DIR / "outputs/workflow-1"),
                                operation_type=Operation.ALL
                            )
                        )

local_site.add_directories(local_shared_scratch, local_local_storage)
sc.add_sites(local_site)
sc.write(sc_file)

# --- executables --------------------------------------------------------------
tc = TransformationCatalog()
keg = Transformation(
        "keg",
        pfn="/usr/bin/pegasus-keg",
        site="condorpool",
        is_stageable=False
    )
tc.add_transformations(keg)
tc.write(tc_file)

# --- workflow -----------------------------------------------------------------
wf = Workflow(name="workflow-1")
j = Job(keg).add_args("-o", "out.txt", "-T", 1).add_outputs(File("out.txt"))
wf.add_jobs(j)
wf.write(str(TOP_DIR / "workflow.yml"))

# REQUIRED: plan, but do not submit
wf.plan(conf=props_file)



