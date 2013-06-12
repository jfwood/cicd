#!/usr/bin/env bash

# This is the first script to run in the initial Jenkins job.

pep8 . > pep8.txt
python -m coverage xml --include=barbican*
pylint -f parseable -d I0011,R0801 barbican | tee pylint.out
exit 0
