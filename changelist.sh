#!/bin/bash
# Copyright (C) 2012 Texas Instruments
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Tony Lofthouse <tony.lofthouse@ti.com>
#
# Description: See help()
#
# Dependencies:
# awk, fgrep, ssh, git, cat, tac
#
#_p_fromgitcommit=6547d805fa1fa4a5f4b7b2daf9b54aa899c75f00
#_p_branch=p-android-omap-3.0
#_p_project=kernel/omap
_p_server=review.omapzoom.org
_p_project=
_p_branch=
_p_fromgitcommit=

# Misc options
_p_full=
_p_printfetch=

_p_whatismyname=`basename $0`
help()
{
cat <<HERE
usage: $_p_whatismyname [-f] [-i] -c <commit-id> -p <project> -b <branch> [-s <server>]
usage: $_p_whatismyname -G

The purpose of this script is to search your local git repository and use the
change-id information and obtain information about uploaded git commits

This can be helpful when sharing the changes with other people. Obviously
this requires due diligence with the maintenance of Change-Id information in
the git commits.

-c <commit-id>
	Where <commit-id> is a commit id in your local git history (see git log).
	You can also use short cuts like HEAD~3
-p <project>
	The git/gerrit project on the gerrit server
-b <branch>
	The git branch in gerrit
-s <server>
	The gerrit server. It is suggested that you use a server name which is
	configured in your .ssh/config for e.g.:

	Host review.omapzoom.org
	User a0741364
	Port 29418
	PreferredAuthentications publickey
	ProxyCommand /usr/bin/corkscrew wwwgate.ti.com 80 %h %p
-G
	Look at the last few local commits and print out the projects and
	branches.
-f
	Print full gerrit info per commit
-t
	Get fetch information

Example:

Say you have uploaded three commits to gerrit and what to share the review URLs

	changelist.sh -c HEAD~3 -p platform/hardware/ti/omap4xxx -b p-ics-mr1

This will output:

Uploaded commits from: review.omapzoom.org: platform/hardware/ti/omap4xxx: p-ics-mr1

  subject: hwc: changes for blit framebuffers
  url: http://review.omapzoom.org/18950
  subject: hwc: Add some functions to aid debug of Post2() api
  url: http://review.omapzoom.org/19167
  subject: HWC: Simplify RGZ blit interface so HWC does less
  url: http://review.omapzoom.org/18711

Adding the -t option will also show the git fetch commands to obtain the uploaded
patches:

changelist.sh -c HEAD~4 -p platform/hardware/ti/omap4xxx -b p-ics-mr1 -t

  subject: Support BLIT_ALL when S3D is enabled
  url: http://review.omapzoom.org/19202
    git fetch ssh://review.omapzoom.org/platform/hardware/ti/omap4xxx refs/changes/02/19202/3 && git cherry-pick FETCH_HEAD
  subject: HWC: Simplify RGZ blit interface so HWC does less
  url: http://review.omapzoom.org/18711
    git fetch ssh://review.omapzoom.org/platform/hardware/ti/omap4xxx refs/changes/11/18711/5 && git cherry-pick FETCH_HEAD
  subject: hwc: Add some functions to aid debug of Post2() api
  url: http://review.omapzoom.org/19167
    git fetch ssh://review.omapzoom.org/platform/hardware/ti/omap4xxx refs/changes/67/19167/4 && git cherry-pick FETCH_HEAD
  subject: hwc: changes for blit framebuffers
  url: http://review.omapzoom.org/18950
    git fetch ssh://review.omapzoom.org/platform/hardware/ti/omap4xxx refs/changes/50/18950/8 && git cherry-pick FETCH_HEAD


HERE
}

git_log()
{
	git log $_p_fromgitcommit.. | fgrep -e Change-Id: | tac
}

gerrit_query()
{
	ssh -n $_p_server gerrit query --current-patch-set status:open project:$_p_project branch:$_p_branch change:$_p_changeid 
}

gerrit_query_changeid()
{
	ssh -n $_p_server gerrit query change:$_p_changeid 
}


gerrit_printfetch()
{
	if [ -n "$_p_printfetch" ] ; then
		fgrep -e subject: -e url: -e ref: | awk "/subject:/,/url:/ { print } /ref:/{ print \"    git fetch ssh://$_p_server/$_p_project \" \$2 \" && git cherry-pick FETCH_HEAD\" }"
	else
		fgrep -e subject: -e url: -e ref: 
	fi
}

gerrit_output()
{
	if [ -n "$_p_full" ] ; then
		cat
	else
		gerrit_printfetch
	fi
}


while getopts "tfc:b:p:s:g:G" opt; do
	case $opt in
	t)
	_p_printfetch=1
	;;
	f)
	_p_full=1
	;;
	c)
	_p_fromgitcommit=$OPTARG
	;;
	b)
	_p_branch=$OPTARG
	;;
	p)
	_p_project=$OPTARG
	;;
	s)
	_p_server=$OPTARG
	;;
	G)
	echo Find out which project and branch is being used from last 4 commits
	_p_fromgitcommit=HEAD~4
	git_log | while read _ctext _p_changeid; do
		gerrit_query_changeid | fgrep -e subject: -e project: -e branch:
		_p_changeid=
	done
	exit 0
	;;
	g)
	_p_fromgitcommit=$OPTARG
	git_log | while read _ctext _p_changeid; do
		gerrit_query_changeid | fgrep -e subject: -e project: -e branch:
	done
	exit 0
	;;
	\?)
	help
	echo "Invalid option: -$OPTARG" >&2
	exit 1
	;;
	:)
	echo "Option -$OPTARG requires an argument." >&2
	exit 1
	;;
	esac
done

if [ ! -n "$_p_fromgitcommit" ] ; then
	echo Need to set commit to search for
	exit 1
elif [ ! -n "$_p_branch" ] ; then
	echo Need to set branch to search for
	exit 1
elif [ ! -n "$_p_project" ] ; then
	echo Need to set git project to search for
	exit 1
fi


echo Uploaded commits from: $_p_server: $_p_project: $_p_branch
echo
git_log | while read _ctext _p_changeid; do
	gerrit_query | gerrit_output
done
