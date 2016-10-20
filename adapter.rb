# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'rubygems'
require 'bundler/setup'
require 'json'

require 'myst'

include Myst::Providers::VCloud

def delete_instance(data)
  credentials = data[:datacenter_username].split('@')
  provider = Provider.new(endpoint:     data[:vcloud_url],
                          organisation: credentials.last,
                          username:     credentials.first,
                          password:     data[:datacenter_password])
  datacenter  = provider.datacenter(data[:datacenter_name])
  instance    = datacenter.compute_instance(data[:name])
  instance.tasks.each { |task| task.waitForTask(0, 1000) }

  instance.delete unless instance.vapp.nil?

  'instance.delete.vcloud.done'
rescue => e
  puts e
  puts e.backtrace
  'instance.delete.vcloud.error'
end

unless defined? @@test
  @data       = { id: SecureRandom.uuid, type: ARGV[0] }
  @data.merge! JSON.parse(ARGV[1], symbolize_names: true)
  original_stdout = $stdout
  $stdout = StringIO.new
  begin
    @data[:type] = delete_instance(@data)
    if @data[:type].include? 'error'
      @data['error'] = { code: 0, message: $stdout.string.to_s }
    end
  ensure
    $stdout = original_stdout
  end

  puts @data.to_json
end
