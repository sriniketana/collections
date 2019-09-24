#!/bin/bash

GITHUB_APPSODY_STACKS="https://github.com/appsody/stacks.git"
if [ -z $TEST_MERGE_REPO ]; then 
    GITHUB_COLLECTIONS="https://${GITHUB_TOKEN}@github.com/kabanero-io/collections.git"
else
     GITHUB_COLLECTIONS=$TEST_MERGE_REPO
fi
BRANCH_COLLECTIONS_STAGING="staging_stacks_master"
BRANCH_COLLECTIONS_STACKS="master"
BRANCH_APPSODY_STACKS="master"

if [ -z $WORKSPACE ]; then
    export WORKSPACE="./merge"
fi

if [ -d $WORKSPACE ]; then
   echo "$WORKSPACE directory already exists, please specify a new directory name"
   exit 1
fi

echo "Creating workspace directory"
mkdir -p  $WORKSPACE/collections
if [ $? -ne 0 ]
then
   echo "Unable to create workspace directory: '$WORKSPACE'"
   exit 1
fi

echo "Cloning current $GITHUB_COLLECTIONS repository"
cd $WORKSPACE/collections
git clone $GITHUB_COLLECTIONS .
rc=$?
if [ $rc -ne 0 ]
then
   echo "git clone $GITHUB_COLLECTIONS failed, rc=$rc."
   exit $rc
fi

echo "Setting merge strategy to `ours`"
git config merge.ours.driver true

echo "Checking out $BRANCH_COLLECTIONS_STAGING from $GITHUB_COLLECTIONS repository"
git checkout $BRANCH_COLLECTIONS_STAGING 2> /dev/null
rc=$?
if [ $rc -ne 0 ]
then
    echo "Branch $BRANCH_COLLECTIONS_STAGING doesnt exist so will checkout as new branch"
    git checkout -B $BRANCH_COLLECTIONS_STAGING 2> /dev/null
    rc=$?
    if [ $rc -ne 0 ]
    then
       echo "git checkout -B $BRANCH_COLLECTIONS_STAGING from repo failed, $rc."
       exit $rc
    fi
fi

echo "Cloning current $GITHUB_APPSODY_STACKS repository"
git clone --no-tags $GITHUB_APPSODY_STACKS stacks

git fetch --no-tags stacks
rc=$?
if [ $rc -ne 0 ]
then
   echo "git fetch --no-tags stacks from latest repo failed, $rc."
   exit $rc
fi

echo "Merging branches"
result=$(git merge --allow-unrelated-histories -m "Merge latest stacks level" FETCH_HEAD | tee /dev/tty)
rc=$?
echo "Return code from merge is $rc."
if [ $rc -ne 0 ]
then
   echo "Merge from stacks mirror failed, $rc."
   exit $rc
else
   if [[ $result = *"Already up to date"* ]]; then
      exit 0;
   fi
   # Belt and braces check to ensure we exit if we have a merge conflict
   if [[ $result = *"Automatic merge failed;"* ]]; then
       echo "***********************"
       echo "****** !FAILURE! ******"
       echo "***********************"
       exit 1;
   fi
fi

echo "Running 'git push origin $BRANCH_COLLECTIONS_STAGING --no-tags'"
git push origin $BRANCH_COLLECTIONS_STAGING --no-tags -v
rc=$?
if [ $rc -ne 0 ]
then
   echo "Push failed, $rc."
   exit $rc
fi

echo "Completed update process... git status:"
git status

echo "Creating pull request for latest changes"
hub pull-request -b $BRANCH_COLLECTIONS_STACKS -h $BRANCH_COLLECTIONS_STAGING -m "Merge of latest appsody/stacks master branch"
rc=$?
if [ $rc -ne 0 ]
then
   echo "Creation of pull request failed, $rc."
   exit $rc
fi

echo "**********************"
echo "****** SUCCESS! ******"
echo "**********************"
