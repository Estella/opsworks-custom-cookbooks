node[:deploy].each do |app_name, deploy|
  if deploy[:application] == "technic_forums"
    script "pre_configure" do
      interpreter "bash"
      user "root"
      cwd "#{deploy[:deploy_to]}/current"
      code <<-EOH
      ln -s /vol/repo/forumdata/data/* data
      ln -s /vol/repo/forumdata/styles/* styles
      ln -s /vol/repo/forumdata/sitemap/* sitemap
      EOH
    end

    template "#{deploy[:deploy_to]}/current/library/config.php" do
      source "config.php.erb"
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
  end
end