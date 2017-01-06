#!/bin/bash

set -eu

fail() {
    rc="$1"
    shift
    echo "ERROR: $@"
    exit "$rc"
}

[ $# -eq 1 -a -n "$1" ] || fail 2 "USAGE: $(basename $0) role"

ROLE="$1"
REPO="ansible-role-$ROLE"

[ -e "$REPO" ] && fail 2 "$REPO already exists"

git init "$REPO"
pushd "$REPO"
git remote add parent https://github.com/openmicroscopy/infrastructure.git
git remote add template https://github.com/manics/infrastructure-extract-ansible-role.git
git fetch --all
git reset --hard parent/master
[ -d "ansible/roles/$ROLE" ] || fail 2 "Invalid role $ROLE"
git filter-branch --subdirectory-filter ansible/roles/$ROLE/

GH_TOKEN=$(git config github.token || :)
if [ -n "$GH_TOKEN" ]; then
    SSH_REPO=$(curl https://api.github.com/user/repos \
        -H "Authorization: token $GH_TOKEN" \
        -d "{ \"name\":\"$REPO\" }" | jq -r '.ssh_url' || :)
    [ -n "$SSH_REPO" -a "$SSH_REPO" != "null" ] && git remote add origin "$SSH_REPO" || echo "WARNING: failed to create GitHub repository $REPO"
fi

echo "Adding the galaxy infrastructure from OME template"
echo "You must manually edit and commit this, then push to GitHub"
git cherry-pick -n 0987b2dac45cabf305b730b1146556fbd5448206
git status
