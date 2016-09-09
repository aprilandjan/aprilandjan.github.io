#!/bin/bash -l

GIT_REPO=git@github.com:aprilandjan/aprilandjan.github.io.git
GIT_CLONE=$HOME/github/aprilandjan.github.io
TMP_GIT_CLONE=$HOME/github/tmp/aprilandjan.github.io
PUBLIC_WWW=/var/www/blog

git clone $GIT_REPO $TMP_GIT_CLONE
jekyll build --source $TMP_GIT_CLONE --destination $PUBLIC_WWW
rm -Rf $TMP_GIT_CLONE
exit