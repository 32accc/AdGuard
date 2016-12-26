#!/bin/sh

#  getExtJsLibs.sh

#   This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
#   Copyright © 2015-2017 Performix LLC. All rights reserved.
#
#   Adguard for iOS is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Adguard for iOS is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.


LibsFile="${SRCROOT}/ActionExtension/js/ExternalLibsSources.js"

Download()
{
echo -n "${1}"
curl -s "${1}" >> "${LibsFile}"
if [ ! $? == 0 ]; then
echo " - fail"
rm -f "${LibsFile}"
exit 1
fi

echo " - done"
}

echo "Downloading external libs sources.."

rm -f "$LibsFile"


Download "${ACTION_JAVASCRIPT_LIB01}"
Download "${ACTION_JAVASCRIPT_LIB02}"
Download "${ACTION_JAVASCRIPT_LIB03}"
Download "${ACTION_JAVASCRIPT_SELECTOR}"
Download "${ACTION_JAVASCRIPT_RULE_CONSTRUCTOR}"

echo "Done"
