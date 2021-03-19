#!/bin/bash
set -e

let LEN=$1+$2
for i in $(seq 1 $LEN); do
    if [ $i -le $1 ]; then
        mkdir -p wf-$i
        sed "s/workflow-1/workflow-$i/g" sample_workflow.py > wf-$i/workflow-$i.py
    else
        mkdir -p wf-$i-will-fail
        sed -e "s/workflow-1/workflow-$i/g" \
            -e "s;/usr/bin/pegasus-keg;/bad-path;" \
            sample_workflow.py > wf-$i-will-fail/workflow-$i.py
    fi
done
