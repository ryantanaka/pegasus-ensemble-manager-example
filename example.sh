# 0. setup: clear existing db (just for this example) and create new one
echo "clearing ~/.workflow.db and creating a new one"
rm -f ~/.pegasus/workflow.db
pegasus-db-admin create

# setup: clearing files from previous runs
rm -f ~/.pegasus/ensembles/myruns/*.log \
    ~/.pegasus/ensembles/myruns/*.plan* \
    ./workflows/wf-will-fail/if.txt

# setup: increase interval at which ensemble manager processes runs
#    configured in ~/.pegasus/service.py
echo "EM_INTERVAL = 5" >> ~/.pegasus/service.py

# 1. pegasus-ensemble manager must be started
#    Will run it in the background and give it a few seconds to start before
#    issuing some commands to it.
echo "starting pegasus-ensemble manager in the background, see em_logs for logs"
pegasus-em server --verbose --debug > em_logs 2>&1 &
EM_PID=$!
sleep 5

# 2. creating an ensemble
echo "creating ensemble: myruns"
pegasus-em create myruns

# 3. configuring ensemble properties
#    There will be at most 2 workflows being planned at a time and at most 2 workflows
#    running at a time.
echo "configuring ensemble max-planning and max-running"
pegasus-em config myruns --max-planning=2 --max-running=2

# 4. add a workflow to the myruns ensemble (workflow created used java api and 
#    planned in shell script).
echo "adding pre 5.0 style workflow to ensemble"
pegasus-em submit myruns.wf-0-java-based ./workflows/wf-java/plan.sh

# 5. add a workflow to the myruns ensemble that will fail due to a missing input file
echo "adding bad workflow to ensemble"
pegasus-em submit myruns.wf-1-will-fail ./workflows/wf-will-fail/workflow.py

# 6. add more workflows (generated using new python api)
NUM_WORKFLOWS=2
echo "generating $NUM_WORKFLOWS more workflow scripts"
for i in $(seq 1 $NUM_WORKFLOWS); do
    mkdir -p workflows/wf-$i
    sed "s/workflow-1/workflow-$i/g" sample_workflow.py > workflows/wf-$i/workflow.py
    chmod u+x workflows/wf-$i/workflow.py

    echo "adding myruns.wf-$i"
    pegasus-em submit myruns.wf-$i workflows/wf-$i/workflow.py
    pegasus-em priority myruns.wf-$i -p $i
done

# 7. monitor status of wall workflows in the myruns ensemble for 30s (notice state of each workflow
timeout --foreground 120 watch -n 1 pegasus-em workflows myruns

# 8. see pegasus-status output for a specific workflow
echo "using pegasus-status to check the status of the first workflow"
pegasus-em status myruns.wf-0-java-based

# 9. see pegasus-analyzer output for one of the workflows we expect to fail
echo "using pegasus-analyzer to see the output for myruns.wf-will-fail"
pegasus-em analyze myruns.wf-1-will-fail

# 10. fix failed workflow, and re-run
echo "fixing failed workflow by adding missing input file; re-running from ensemble manager"
echo "sample input" > workflows/wf-will-fail/if.txt
pegasus-em rerun myruns.wf-1-will-fail

# 11. observe failed workflow run to completion
timeout --foreground 120 watch -n 1 pegasus-em workflows myruns

# remove generated workflows
ls workflows \
    | grep -P "wf-[0-9]" \
    | xargs -d "\n" printf -- "workflows/%s\n" \
    | xargs -n1 rm -r

# stop the pegasus-ensemble manager (typically, leave it on)
kill $EM_PID




