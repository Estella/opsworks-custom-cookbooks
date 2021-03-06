node[:deploy].each do |app_name, deploy|
  if deploy[:application] == "platform"
    script "set_permissions" do
      interpreter "bash"
      user "root"
      cwd "#{deploy[:deploy_to]}/current"
      code <<-EOH
      chmod -R 777 storage
      EOH
    end

    script "link_launcher" do
      interpreter "bash"
      user "root"
      cwd "#{deploy[:deploy_to]}/current/public"
      code <<-EOH
      rm -rf launcher
      ln -sf /vol/repo/launcher
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

    template "#{deploy[:deploy_to]}/current/application/config/cache.php" do
      source "cache.php.erb"
      mode 0660
      group deploy[:group]

      if platform?("ubuntu")
        owner "www-data"
      elsif platform?("amazon")   
        owner "apache"
      end

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