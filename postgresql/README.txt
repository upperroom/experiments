
# The oldest issue of URE online:
http://devotional.upperroom.org/devotionals/1997-09-01

# The oldest issue of EAA online:
http://elaposentoalto.upperroom.org/es/devotionals/1999-07-01


 !    The `heroku` gem has been deprecated and replaced with the Heroku Toolbelt.
 !    Download and install from: https://toolbelt.heroku.com
 !    For API access, see: https://github.com/heroku/heroku.rb

Before attempting to run any data-related commands(eg. db:schema:load, db:migrate, test:prepare, etc.), you must do the following:

$ cp config/database.dist.yml config/database.yml
Edit the username and password fields to correspond with your local postgres credentials.

$ createuser owning_user
$ rake db:create
$ psql -U <username> -f ./db/development_structure.sql upperroom_development
$ rake db:schema:load
$ rake db:test:prepare




Since this application is so tied to particular content, many of the specs / cucumber scenarios rely on production data. Before running specs for the first time, import the production database into the test database:

$ heroku pgbackups:capture --expire --app upperroom
$ curl -o latest.dump `heroku pgbackups:url --app upperroom`
$ pg_restore --verbose --clean --no-acl --no-owner -h localhost -U <username> -d upperroom_test latest.dump

NOTE: in order to effectively work on content-related issues, you might want to go ahead and restore the development database to whatever is in the dump as well.
$ pg_restore --verbose --clean --no-acl --no-owner -h localhost -U <username> -d upperroom_development latest.dump
