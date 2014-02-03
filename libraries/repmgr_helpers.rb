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
end

Chef::Recipe.send(:include, RepmgrHelpers)
Chef::Resource::RubyBlock.send(:include, RepmgrHelpers)
