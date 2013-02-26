node[:deploy].each do |app_name, deploy|
  if deploy[:application] == "solder"
    script "copy_config" do
      interpreter "bash"
      user "root"
      cwd "#{deploy[:deploy_to]}/current/application"
      code <<-EOH
      cp -r config-sample/ config/
      rm -f config/database.php
      rm -f config/solder.php
      EOH
    end

    script "copy_htaccess" do
      interpreter "bash"
      user "root"
      cwd "#{deploy[:deploy_to]}/current/public"
      code <<-EOH
      cp .htaccess-sample .htaccess
      EOH
    end

    template "#{deploy[:deploy_to]}/current/application/config/database.php" do
      source "database.php.erb"
      mode 0660
      group deploy[:group]

      if platform?("ubuntu")
        owner "www-data"
      elsif platform?("amazon")   
        owner "apache"
      end

      variables(
        :host =>     (deploy[:database][:host] rescue nil),
        :user =>     (deploy[:database][:username] rescue nil),
        :password => (deploy[:database][:password] rescue nil),
        :db =>       (deploy[:database][:database] rescue nil)
      )

     only_if do
       File.directory?("#{deploy[:deploy_to]}/current")
     end
    end

    template "#{deploy[:deploy_to]}/current/application/config/solder.php" do
      source "solder.php.erb"
      mode 0660
      group deploy[:group]

      if platform?("ubuntu")
        owner "www-data"
      elsif platform?("amazon")   
        owner "apache"
      end

      variables(
        :repo_location => (node[:solder][:repo_location] rescue nil),
        :mirror_url => (node[:solder][:mirror_url] rescue nil)
      )

     only_if do
       File.directory?("#{deploy[:deploy_to]}/current")
     end
    end

    script "run_migrations" do
      interpreter "bash"
      user "root"
      cwd "#{deploy[:deploy_to]}/current"
      code <<-EOH
      php artisan migrate
      EOH
    end
  end
end