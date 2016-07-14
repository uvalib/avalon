set :application, "avalon"
set :repository,  "git://github.com/uvalib/avalon.git"
set :rails_env, ENV['RAILS_ENV'] || "development"

set(:deployment_host) { "avalontest.lib.virginia.edu" }  # Host(s) to deploy to
set(:deploy_to) { "/usr/local/projects/avalon" }  # Directory to deploy into
set(:user) { ENV['USER'] }                # User to deploy as
set :branch, ENV['SCM_BRANCH'] || "capistrano_updates_for_uva"       # Git branch to deploy

set :hls_dir, "/var/avalon/hls_streams"

set :bundle_without, rails_env == "development" ? "production" : "development debug"

role :web, deployment_host
role :app, deployment_host
role :db, deployment_host, :primary => true

before "bundle:install", "deploy:link_local_files"
before "deploy:finalize_update", "deploy:remove_symlink_targets"
after "deploy:update_code", "deploy:symlink_dirs"
after "deploy:update_code", "deploy:migrate"
after "deploy:create_symlink", "deploy:trust_rvmrc"
if ENV['AVALON_REINDEX']
  after "deploy:create_symlink", "deploy:reindex_everything"
end

set(:shared_children) { 
  %{
    config/authentication.yml 
    config/avalon.yml 
    config/controlled_vocabulary.yml
    config/database.yml 
    config/environments/development.rb
    config/fedora.yml 
    config/lti.yml 
    config/matterhorn.yml 
    config/role_map_#{fetch(:rails_env)}.yml
    config/secrets.yml
    config/solr.yml
    log
    tmp/pids
    db/development.sqlite3
  }.split
}

namespace :deploy do
  task :remove_symlink_targets do
    shared_children.each do |target|
      t = File.join(latest_release,target)
      run "if [ -f #{t} ]; then rm #{t}; fi"
    end
  end

  task :symlink_dirs do
    run "cd #{current_release}; ln -s #{hls_dir} #{latest_release}/public/streams"
  end

  task :migrate do
    run "cd #{current_release}; bundle exec rake RAILS_ENV=#{rails_env} db:migrate"    
  end

  task :link_local_files do
    link_shared_file "Gemfile.local", "Gemfile.local"
    link_shared_file "user_auth_cas.rb", "config/initializers/user_auth_cas.rb"
    link_shared_file "iu-ldap.rb", "config/initializers/iu-ldap.rb"
    link_shared_file "permalink.rb", "config/initializers/permalink.rb"
  end

  task :trust_rvmrc do
    run "/home/md5wz/.rvm/bin/rvm rvmrc trust #{latest_release}"
  end

  task :start do
    run "cd #{current_release} && #{rake} RAILS_ENV=#{rails_env} delayed_job:start"
  end

  task :stop do
    run "cd #{current_release} && #{rake} RAILS_ENV=#{rails_env} delayed_job:stop"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_release} && #{rake} RAILS_ENV=#{rails_env} delayed_job:restart"
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :reindex_everything do
    run "cd #{current_release} && RAILS_ENV=#{rails_env} bundle exec rake avalon:reindex"
  end
end

def link_shared_file source, target 
    run "if [ -f #{shared_path}/#{source} ]; then ln -s #{shared_path}/#{source} #{latest_release}/#{target}; fi"
end
