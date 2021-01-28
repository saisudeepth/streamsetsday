#!/bin/bash
# Wait for SQL Server to be up and running
echo "Entering $0"

# Run the setup script to create the DB and the schema in the DB
if [ -e $(dirname $0)/streamsets-days.sql -a ! -e /tmp/completed-initialization-flag ]
then
  echo "Enabling sqlagent"
  /opt/mssql/bin/mssql-conf set sqlagent.enabled true

  echo "Waiting 30 seconds to give SQL Server enough time to start up"
  sleep 30s

  echo $0: Creating database and table | tee -a /tmp/sqlcmd.log
  /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -i $(dirname $0)/streamsets-days.sql | tee -a /tmp/sqlcmd.log

  echo "Sleeping for 5 seconds to let MS SQL complete transactions"  # No clue why this is required.
  sleep 5s
  echo $0: Loading data into EMPLOYEE | tee -a /tmp/sqlcmd.log
  /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d streamsetsdays -i $(dirname $0)/INSERT_EMPLOYEE.sql |
    tee -a /tmp/sqlcmd.log  | sed 's/([0-9]* rows affected)/./g;' | tr -d '\n'
  echo
  echo $0: Loading data into CUSTOMER | tee -a /tmp/sqlcmd.log
  /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d streamsetsdays -i $(dirname $0)/INSERT_CUSTOMER.sql |
    tee -a /tmp/sqlcmd.log  | sed 's/([0-9]* rows affected)/./g;' | tr -d '\n'
  echo
  date > /tmp/completed-initialization-flag # Prevent reinitializing on restart
fi


echo "Exiting $0"
