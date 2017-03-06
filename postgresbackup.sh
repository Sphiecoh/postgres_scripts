#!/bin/bash
pg_user="pgbackup" #pg backup user 
pg_host="localhost" 
pg_port="5432" 
backup_db_arr=(postgres) # Name of the database to be backed up, separating multiple databases 
backup_location=/var/www/postgresql # Backup data storage location; please do not end with a "/" and leave it at its default, for the program to automatically create a folder 
expire_backup_delete="ON" # Whether to delete outdated backups or not expire_days=3 # Set the expiration time of backups, in days (defaults to three days); this is only valid when the `expire_backup_delete` option is "ON"
# We do not need to modify the following initial settings below
backup_time=`date +%Y%m%d%H%M` # Define the backup time format backup_Ymd=`date +%Y-%m-%d` # Define the backup directory date time backup_3ago=`date --date '3 days ago' +%Y-%m-%d` # 3 days before the date 
backup_dir=$backup_location/$backup_Ymd # Full path to the backup folder welcome_msg="Welcome to use Postgresql backup tools!" # Greeting

# Determine whether to MySQL is running; if not, then abort the backup
pg_ps=`ps -ef | grep postgresql | wc -l` pg_listen=`netstat -an | grep LISTEN | grep $pg_port | wc -l` 
if [ "$pg_ps" -eq 0 ]; then
  echo "ERROR: Postgresql is not running! backup aborted!"

else
  echo $welcome_msg
fi

# Connect to the mysql database; if a connection cannot be made, abort the backup
psql -h $pg_host -p $pg_port -U $pg_user -d postgres -c 'select * from pg_database;'

flag=`echo $?` 
if [ "$flag" -ne 0 ]; then
  exit
 else
  echo "Postgres connect ok! Please wait......"
   # Determine whether a backup database is defined or not. If so, begin the backup; if not, then abort 
  if [ "$backup_db_arr" != "" ]; then
       # dbnames=$(cut -d ',' -f 1-5 $backup_database)
       # echo "arr is(${backup_db_arr [@]})"
      for dbname in ${backup_db_arr[@]}
      do
          echo "database $dbname backup start..."
          `mkdir -p $backup_dir`
          `pg_dump -h $pg_host -p $pg_port -U $pg_user -f $backup_dir/$dbname-$backup_time.tar -F tar $dbname`
          flag=`echo $?`
          if [ $flag -eq 0 ]; then
              echo "database $dbname successfully backed up to $backup_dir/$dbname-$backup_time.tar"
          else
              echo "database $dbname backup has failed!"
          fi

      done
  else
      echo "ERROR: No database to backup! backup aborted!"
      exit
  fi
   # If deleting expired backups is enabled, delete all expired backups 
  if [ "$expire_backup_delete"=="ON" -a "$backup_location"!="" ]; then
      # `find $backup_location/-type d -o -type f -ctime + $expire_days-exec rm -rf {} \;`
      `find $backup_location/ -type d -mtime + $expire_days | xargs rm -rf`
      echo "Expired backup data delete complete!"
  fi
  echo "All databases have been successfully backed up! Thank you!"
  exit
fi

