#!/bin/sh
#
cat > ~/vcloudrc.sh <<-EOF
export VCD_ORG=$vcd_org
export VCD_USERID=$vcd_user
export VCD_PASSWORD='$vcd_password'
export VCD_VDC="$vcd_vdc"
export VCD_URL=$vcd_url
export OS_AUTH_URL=$os_auth_url
export OS_PASSWORD='$os_password'
export OS_PROJECT_NAME=$os_project_name
export OS_USERNAME=$os_username
EOF