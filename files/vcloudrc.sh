#!/bin/sh
#
cat > ~/vcloudrc.sh <<-EOF
export VCD_ORG=$vcd_org
export VCD_USERID=$vcd_user
export VCD_PASSWORD='$vcd_password'
export VCD_VDC="$vcd_vdc"
export VCD_URL=$vcd_url
EOF