set -e
set -v

# 0. setup db
pegasus-db-admin create

# 1. pegasus-ensemble manager must be started
pegasus-em server &

# 2. creating an ensemble
pegasus-em create myruns

# 3. configuring ensemble properties
#    There will be at most 2 workflows being planned at a time and at most 2 workflows
#    running at a time.
pegasus-em config myruns --max-planning=2 --max-running=2

# 4. add a workflow to the myruns ensemble (workflow created used java api and 
#    planned in shell script).
pegasus-em submit myruns.run0 ./workflows/wf-java/plan.sh

# 5. add 7 more workflows 
# generate some sample workflows (4 will succeed, 3 will fail when run)
./workflows/generate_more_workflows.sh 4 3

# add those sample workflows to the myruns ensemble
let i=1
for f in `find . -type f -name "*.py"`; do
    echo "adding $f to myruns"
    pegasus-em submit myruns.run$i $f
    let i=i+1
done

# 6. monitor status of wall workflows in the myruns ensemble for 30s (notice state of each workflow)
for i in $(seq 1 30); do
    pegasus-em workflows myruns
    sleep 1
    clear
done

# 7. see pegasus-status  output for a specific workflow
pegasus-em status myruns.run1
clear




