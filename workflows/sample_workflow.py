#!/usr/bin/env python3
import logging
from pathlib import Path

from Pegasus.api import *

logging.basicConfig(level=logging.INFO)

# --- working directory setup --------------------------------------------------
WORK_DIR = Path.home() / "workflows"
WORK_DIR.mkdir(exist_ok=True)

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
sc.write()

# --- executables --------------------------------------------------------------
tc = TransformationCatalog()
keg = Transformation(
        "keg",
        pfn="/usr/bin/pegasus-keg",
        site="condorpool",
        is_stageable=False
    )
tc.add_transformations(keg)
tc.write()

# --- workflow -----------------------------------------------------------------
wf = Workflow(name="workflow-1")
j = Job(keg).add_args("-o", "out.txt", "-T", 20).add_outputs(File("out.txt"))
wf.add_jobs(j)

# REQUIRED: plan, but do not submit
wf.plan()



