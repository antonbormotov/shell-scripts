#!/bin/sh

# 1) Get new tag
NEW_TAG="%TAG%"
REPOSITORY="organisation/repository"
GITHUB_TOKEN=
echo ${NEW_TAG}

# 2) Get current latest tag
OLD_TAG=$(curl -s --get "https://api.github.com/repos/${REPOSITORY}/releases/latest?access_token=${GITHUB_TOKEN}" | grep "tag_name" | cut -d '"' -f4)
echo ${OLD_TAG}

# 3) Merge develop to master
echo "fetching"
git fetch --quiet --tags origin develop
echo "merging"
git merge --no-ff --no-edit --quiet origin/develop
echo "pushing"
git push origin master

# 4) Get release notes for github.com
GITHUB_RELEASE_NOTES=$(git log --merges --pretty=format:%b ${OLD_TAG}..HEAD | sed '/^\s*$/d' | sed ':a;N;$!ba;s/\n/\\n/g' | tr -d '\n' | sed 's/\"/\\"/g')
echo ${GITHUB_RELEASE_NOTES}

# 5) Create new tag and latest release pointer
curl -s --data "{\"tag_name\": \"${NEW_TAG}\",\"target_commitish\": \"master\",\"name\": \"${NEW_TAG}\",\"body\": \"Release version ${NEW_TAG}:\n${GITHUB_RELEASE_NOTES}\",\"draft\": false,\"prerelease\": false}" "https://api.github.com/repos/${REPOSITORY}/releases?access_token=${GITHUB_TOKEN}"

# 6) Get release notes for email and export env variable
EMAIL_RELEASE_NOTES=$(git log --merges --pretty=format:%b ${OLD_TAG}..HEAD | sed '/^\s*$/d' | sed ':a;N;$!ba;s/\n/\<br\>/g' |sed 's/\"/\\"/g')
echo ${EMAIL_RELEASE_NOTES}
echo "##teamcity[setParameter name='env.EMAIL_RELEASE_NOTES' value='${EMAIL_RELEASE_NOTES}']"

