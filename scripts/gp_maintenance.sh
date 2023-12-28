#!/bin/bash
# Path: scripts/gp_maintenance.sh

# Log everything in ./maintenance.log
exec &> >(tee -a "maintenance.log")

# Colorful echo with timestamp
echo_orange() {
  echo -n -e "\033[38;5;214m$(date +"%Y-%m-%d %H:%M:%S") $1\033[0m"
}
echo_green() {
  echo -n -e "\033[38;5;2m$(date +"%Y-%m-%d %H:%M:%S") $1\033[0m"
}
echo_blue() {
  echo -n -e "\033[38;5;4m$(date +"%Y-%m-%d %H:%M:%S") $1\033[0m"
}
echo_red() {
  echo -n -e "\033[38;5;1m$(date +"%Y-%m-%d %H:%M:%S") $1\033[0m"
}

echo_green "Starting the maintenance script \n"
echo_orange "Do you want to disable the crontabs? (y/n):"
read disable_crontabs
if [[ $disable_crontabs == "y" ]]; then
  crontab -l > crontab.gpadmin.`date +%m%d%y`
  crontab -r
  echo_green "Disabled the crontabs \n"
fi

echo_orange "Do you want to list the crontabs? (y/n):"
read list_crontabs
if [[ $list_crontabs == "y" ]]; then
  crontab -l
fi

echo_orange "Do you want to increase the statement memory for gpadmin? (y/n):"
read increase_statement_mem
if [[ $increase_statement_mem == "y" ]]; then
  psql -Atc "alter role gpadmin set statement_mem = '1GB';"
  echo_green "Increased the statement memory for gpadmin \n"
fi

echo_orange "Do you want to disable user logins? (y/n):"
read disable_logins
if [[ $disable_logins == "y" ]]; then
  psql -Atc "select 'alter role '||rolname||' with nologin;' from pg_roles where rolname !='gpadmin' and rolcanlogin;" > disable_logins.sql
  psql -Atc "select 'alter role '||rolname||' with login;' from pg_roles where rolname !='gpadmin' and rolcanlogin;" > enable_logins.sql
  psql -f disable_logins.sql
  echo_green "Disabled user logins \n"
fi

echo_orange "Do you want to see the users with login? (y/n):"
read list_users_with_login
if [[ $list_users_with_login == "y" ]]; then
  psql -Atc "select rolname from pg_roles where rolcanlogin;"
fi

echo_orange "Do you want to restart the database in restriced mode? (y/n):"
read restart_db_in_restricted_mode
if [[ $restart_db_in_restricted_mode == "y" ]]; then
  gpstop -a -M fast
  gpstart -aR
  echo_green "Restarted the database in restriced mode \n"
fi

echo_orange "Do you want to drop orphan temp schema? (y/n):"
read drop_orphan_temp_schema
if [[ $drop_orphan_temp_schema == "y" ]]; then
  cat /dev/null > execute_drop_on_all.sh | psql -d template1 -Atc "select datname from pg_database where datname != 'template0'" | while read a; do echo "Checking database ${a}"; psql -Atc "select 'drop schema if exists ' || nspname || ' cascade;' from (select nspname from pg_namespace where nspname like 'pg_temp%' union select nspname from gp_dist_random('pg_namespace') where nspname like 'pg_temp%' except select 'pg_temp_' || sess_id::varchar from pg_stat_activity) as foo" ${a} > drop_temp_schema_$a.ddl ; echo "psql -f drop_temp_schema_$a.ddl -d ${a}" >> execute_drop_on_all.sh ; done
  sh execute_drop_on_all.sh
  echo_green "Dropped orphan temp schema \n"
fi

echo_orange "Do you want to drop two days old external tables? (y/n):"
read drop_two_days_old_ext_tables
if [[ $drop_two_days_old_ext_tables == "y" ]]; then
  psql -At -f /home/gpadmin/Maintenance/drop_ext_tables.sql > drop_ext_tables.sql
  psql -f drop_ext_tables.sql
  echo_green "Dropped two days old external tables \n"
fi

echo_orange "Do you want to run Full Vacuum, Re-index and Analyze on catalog tables? (y/n):"
read run_full_vacuum_reindex_analyze_on_catalog_tables
if [[ $run_full_vacuum_reindex_analyze_on_catalog_tables == "y" ]]; then
  cp ~/Maintenance/catalog_tables_maintenance.sh catalog_tables_maintenance.sh
  sh catalog_tables_maintenance.sh
  echo_green "Ran Full Vacuum, Re-index and Analyze on catalog tables \n"
fi

echo_orange "Do you want to start the database in normal mode? (y/n):"
read start_db_in_normal_mode
if [[ $start_db_in_normal_mode == "y" ]]; then
  gpstop -a -M fast
  gpstart -a
  echo_green "Started the database in normal mode \n"
fi

echo_orange "Do you want to reset gpadmin statement memory? (y/n):"
read reset_gpadmin_statement_memory
if [[ $reset_gpadmin_statement_memory == "y" ]]; then
  psql -Atc "alter role gpadmin reset statement_mem;"
  echo_green "Reset gpadmin statement memory \n"
fi

echo_orange "Do you want to enable the cronjobs? (y/n):"
read enable_cronjobs
if [[ $enable_cronjobs == "y" ]]; then
  crontab crontab.gpadmin.`date +%m%d%y`
  crontab -l
  echo_green "Enabled the cronjobs \n"
fi

echo_orange "Do you want to see the crontabs? (y/n):"
read list_crontabs
if [[ $list_crontabs == "y" ]]; then
  crontab -l
fi

echo_orange "Do you want to enable the logins for users? (y/n):"
read enable_logins
if [[ $enable_logins == "y" ]]; then
  psql -f enable_logins.sql
  echo_green "Enabled the logins for users \n"
fi

echo_orange "Do you want to see the users with nologin? (y/n):"
read list_users_with_nologin
if [[ $list_users_with_nologin == "y" ]]; then
  psql -Atc "select rolname from pg_roles where not rolcanlogin;"
fi

echo_green "Completed the maintenance script \n"