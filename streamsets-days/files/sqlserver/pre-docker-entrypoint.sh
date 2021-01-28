#!/bin/bash
set -x
# Run Microsoft SQl Server and initialization script (at the same time)
/scripts/execute_create_statements.sh & /opt/mssql/bin/nonroot_msg.sh /opt/mssql/bin/sqlservr
