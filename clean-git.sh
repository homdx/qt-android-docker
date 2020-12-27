#!/bin/bash

git reset --hard
git submodule foreach --recursive 'git reset HEAD . || :'
git submodule foreach --recursive 'git checkout -- . || :'
git clean -d -f -f -x
git submodule foreach --recursive git clean -d -f -f -x
