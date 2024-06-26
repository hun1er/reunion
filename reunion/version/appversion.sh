#!/bin/bash

init()
{
	SOURCE_DIR=$1
	VERSION_FILE=$SOURCE_DIR/reunion/version/version.h
	APPVERSION_FILE=$SOURCE_DIR/reunion/version/appversion.h
	README_FILE=$SOURCE_DIR/reunion/dist/Readme

	if test -z "`git --version`"; then
		echo "Please install git client"
		echo "sudo apt-get install git"
		exit 0
	fi

	# Read old version
	if [ -e $APPVERSION_FILE ]; then
		OLD_VERSION=$(cat $APPVERSION_FILE | grep -wi '#define APP_VERSION' | sed -e 's/#define APP_VERSION[ \t\r\n\v\f]\+\(.*\)/\1/i' -e 's/\r//g')
		if [ $? -ne 0 ]; then
			OLD_VERSION=""
		else
			# Remove quotes
			OLD_VERSION=$(echo $OLD_VERSION | xargs)
		fi
	fi

	# Get major, minor, maintenance and suffix information from version.h
	MAJOR=$(cat $VERSION_FILE | grep -wi '#define VERSION_MAJOR' | sed -e 's/#define VERSION_MAJOR.*[^0-9]\([0-9][0-9]*\).*/\1/i' -e 's/\r//g')
	if [ $? -ne 0 -o "$MAJOR" = "" ]; then
		MAJOR=0
	fi

	MINOR=$(cat $VERSION_FILE | grep -wi '#define VERSION_MINOR' | sed -e 's/#define VERSION_MINOR.*[^0-9]\([0-9][0-9]*\).*/\1/i' -e 's/\r//g')
	if [ $? -ne 0 -o "$MINOR" = "" ]; then
		MINOR=0
	fi

	MAINTENANCE=$(cat $VERSION_FILE | grep -i '#define VERSION_MAINTENANCE' | sed -e 's/#define VERSION_MAINTENANCE.*[^0-9]\([0-9][0-9]*\).*/\1/i' -e 's/\r//g')
	if [ $? -ne 0 -o "$MAINTENANCE" = "" ]; then
		MAINTENANCE=0
	fi

	SUFFIX=$(cat $VERSION_FILE | grep -wi '#define VERSION_SUFFIX' | sed -e 's/#define VERSION_SUFFIX\s*"\(.*\)"/\1/i' -e 's/\r//g')
	if [ $? -ne 0 -o "$SUFFIX" = "" ]; then
		SUFFIX=""
	fi

	BRANCH_NAME=$(git -C $SOURCE_DIR rev-parse --abbrev-ref HEAD)
	if [ $? -ne 0 -o "$BRANCH_NAME" = "" ]; then
		BRANCH_NAME=master
	fi

	COMMIT_COUNT=$(git -C $SOURCE_DIR rev-list --count $BRANCH_NAME)
	if [ $? -ne 0 -o "$COMMIT_COUNT" = "" ]; then
		COMMIT_COUNT=0
	else
		COMMIT_COUNT=$((COMMIT_COUNT % 100))
	fi

	#
	# Configure remote url repository
	#
	# Get remote name by current branch
	BRANCH_REMOTE=$(git -C $SOURCE_DIR config branch.$BRANCH_NAME.remote)
	if [ $? -ne 0 -o "$BRANCH_REMOTE" = "" ]; then
		BRANCH_REMOTE=origin
	fi

	# Get commit id
	COMMIT_SHA=$(git -C $SOURCE_DIR rev-parse --verify HEAD)
	COMMIT_SHA=${COMMIT_SHA:0:7}

	# Get remote url
	COMMIT_URL=$(git -C $SOURCE_DIR config remote.$BRANCH_REMOTE.url)

	URL_CONSTRUCT=0

	if [[ "$COMMIT_URL" == *"git@"* ]]; then

		URL_CONSTRUCT=1

		# Strip prefix 'git@'
		COMMIT_URL=${COMMIT_URL#git@}

		# Strip postfix '.git'
		COMMIT_URL=${COMMIT_URL%.git}

		# Replace ':' to '/'
		COMMIT_URL=${COMMIT_URL/:/\/}

	elif [[ "$COMMIT_URL" == *"https://"* ]]; then

		URL_CONSTRUCT=1

		# Strip prefix 'https://'
		COMMIT_URL=${COMMIT_URL#https://}

		# Strip postfix '.git'
		COMMIT_URL=${COMMIT_URL%.git}

	fi

	if test "$URL_CONSTRUCT" -eq 1; then
		# Append extra string
		if [[ "$COMMIT_URL" == *"bitbucket.org"* ]]; then
			COMMIT_URL=$(echo https://$COMMIT_URL/commits/)
		else
			COMMIT_URL=$(echo https://$COMMIT_URL/commit/)
		fi
	fi

	NEW_VERSION="$MAJOR.$MINOR.$MAINTENANCE.$COMMIT_COUNT$SUFFIX"

	# Update appversion.h if version has changed
	if [ "$NEW_VERSION" != "$OLD_VERSION" ] || [ ! -e "$README_FILE.txt" ] || [ ! -s "$README_FILE.txt" ]; then
		update_appversion
	fi
}

update_appversion()
{
	day=$(date +%d)
	year=$(date +%Y)
	hours=$(date +%H:%M:%S)
	month=$(LANG=en_us_88591; date +"%b")

	# Write Readme.txt
	sed "s/\${APP_VERSION_STRD}/$NEW_VERSION/g" "$README_FILE.tpl" > "$README_FILE.txt"

	# Write appversion.h
	echo Updating appversion.h, new version is '"'$NEW_VERSION'"', the old one was $OLD_VERSION

	echo -e "#ifndef __APPVERSION_H__\r">$APPVERSION_FILE
	echo -e "#define __APPVERSION_H__\r">>$APPVERSION_FILE
	echo -e "\r">>$APPVERSION_FILE
	echo -e "//\r">>$APPVERSION_FILE
	echo -e "// This file is generated automatically.\r">>$APPVERSION_FILE
	echo -e "// Don't edit it.\r">>$APPVERSION_FILE
	echo -e "//\r">>$APPVERSION_FILE
	echo -e "\r">>$APPVERSION_FILE
	echo -e "// Version defines\r">>$APPVERSION_FILE
	echo -e '#define APP_VERSION "'$NEW_VERSION'"\r'>>$APPVERSION_FILE

	echo -e "#define APP_VERSION_C $MAJOR,$MINOR,$MAINTENANCE,$COMMIT_COUNT\r">>$APPVERSION_FILE
	echo -e '#define APP_VERSION_STRD "'$MAJOR.$MINOR.$MAINTENANCE.$COMMIT_COUNT$SUFFIX'"\r'>>$APPVERSION_FILE
	echo -e "#define APP_VERSION_FLAGS 0x0L\r">>$APPVERSION_FILE
	echo -e "\r">>$APPVERSION_FILE
	echo -e '#define APP_COMMIT_DATE "'$month $day $year'"\r'>>$APPVERSION_FILE
	echo -e '#define APP_COMMIT_TIME "'$hours'"\r'>>$APPVERSION_FILE
	echo -e "\r">>$APPVERSION_FILE

	echo -e '#define APP_COMMIT_SHA "'$COMMIT_SHA'"\r'>>$APPVERSION_FILE
	echo -e '#define APP_COMMIT_URL "'$COMMIT_URL'"\r'>>$APPVERSION_FILE
	echo -e "\r">>$APPVERSION_FILE
	echo -e "#endif //__APPVERSION_H__\r">>$APPVERSION_FILE
}

# Initialise
init $*

# Exit normally
exit 0
