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

  def file_last_lines(file, lines = 100)
    # no need to read an entire file and
    # no need for complicated IO#seek on 'nix
    %x(tail -n #{lines} '#{file}').split(/\r?\n/)
  end
end

Chef::Recipe.send(:include, RepmgrHelpers)
Chef::Resource::RubyBlock.send(:include, RepmgrHelpers)
