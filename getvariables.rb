#!/usr/bin/ruby
require 'json'

profiles = []
File.open(File.expand_path('~/.aws/credentials'), 'r') do |f|
  f.each_line do |l|
    next unless l.gsub!(/^\[\s*(\w+)\s*\].*/, '\1')
    l.chomp!
    profiles.push(l)
  end
end

base_amis = Hash.new

data = profiles.map do |account|
  regions_json = `aws ec2 describe-regions --profile #{account} --region us-east-1`
  if $?.exitstatus != 0
    print "Failed to run aws ec2 describe-regions --profile #{account}"
    exit 1
  end
  regions = JSON.parse(regions_json)['Regions'].map { |d| d['RegionName'] }
  regions.map do |region|
    images_json = `aws ec2 describe-images --profile #{account} --region #{region} --filters "Name=tag-key,Values=Name" "Name=tag-value,Values=base-image"`
    if $?.exitstatus != 0
      print "Failed to run aws ec2 describe-images --profile #{account} --region us-east-1"
      exit 1
    end
    images = JSON.parse(images_json)['Images'].sort_by { |hash| hash['ImageId'].to_i }
    unless images.empty?
      latest_image = images.last
      base_amis.merge!(Hash["#{region}" => latest_image["ImageId"]])
    end
  end
end

output = {
  "variable" => {
  "digit_base_ami_id" => {
    "description" => "The DIGIT base ami",
    "default" => base_amis
  }
}
}

File.open('variables.tf.json.new', 'w') { |f| f.puts JSON.pretty_generate(output) }
File.rename 'variables.tf.json.new', 'variables.tf.json'
