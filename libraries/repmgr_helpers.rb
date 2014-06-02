module RepmgrHelpers

  def with_retries(max_count = node[:repmgr][:discovery][:retries] || 3 ,
                   wait_secs = node[:repmgr][:discovery][:wait_secs] || 5)
    retry_count = 0
    begin
      yield
    rescue => error
      if retry_count < max_count
        retry_count += 1
        sleep wait_secs
        retry
      else
        raise error
      end
    end
  end

  def postgresql_in_consistent_state?
    postgresql_log_file = "/var/log/postgresql/postgresql-#{node[:postgresql][:version]}-main.log"
    consistent_state_reached = false
    file_last_lines(postgresql_log_file, 1000).reverse_each do |line|
      if line =~ /database system is ready to accept read only connections/
        consistent_state_reached = true
        break
      elsif line =~ /entering standby mode/
        break
      end
    end
    consistent_state_reached
  end

  def file_last_lines(file, lines = 100)
    # no need to read an entire file and
    # no need for complicated IO#seek on 'nix
    %x(tail -n #{lines} '#{file}').split(/\r?\n/)
  end

  def find_master_node
    if node[:repmgr][:replication][:role] == 'master' then
      node
    else
      if node[:repmgr][:discovery][:master_role]
        search_term = node[:repmgr][:discovery][:master_role]
        raw_search = false
      else
        search_term = 'replication_role:master'
        raw_search = true
      end

      with_retries do
        discovery_search(
          search_term,
          :raw_search => raw_search,
          :environment_aware => node[:repmgr][:replication][:common_environment],
          :minimum_response_time_sec => false,
          :empty_ok => false
        )
      end
    end
  end

end

Chef::Recipe.send(:include, RepmgrHelpers)
Chef::Resource::RubyBlock.send(:include, RepmgrHelpers)
