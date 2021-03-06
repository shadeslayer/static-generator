#!/usr/bin/env ruby

require 'aws'
require 'nokogiri'
require 'date'

def getObjectHash(objectCollection)
  objectHash = {}
  objectCollection.each do |object|
    if object.key.end_with? ".iso"
      tempHash = {}
      fileName = object.key.split('/').last
      date = Date.parse(fileName.split('-')[-2])
      if fileName.include? 'amd64'
        tempHash = { date => {:amd64 => "http://pangea-data.s3.amazonaws.com/" + object.key }}
      end
      if fileName.include? 'i386'
        tempHash = { date => {:i386 => "http://pangea-data.s3.amazonaws.com/" + object.key }}
      end
      ## Merge the arch hash inside of hash instead of overwriting it
      objectHash.merge!(tempHash) { |key, oldval, newval| newval.merge!(oldval) }

      ## Set the right acl
      object.acl = :public_read
    end
  end
  return objectHash
end

unless ARGV[0]
  puts "What do you think you're trying to pull mister!"
  puts "Need path relative to bucket root as argument...."
  exit
end

if File.exist?("#{ENV['HOME']}/.config/aws.json")
    puts "Parsing aws.json config"
    data = File.read("#{ENV['HOME']}/.config/aws.json")
    config = JSON::parse(data, :symbolize_names => true)
    AWS.config(config)
end

s3 = AWS::S3.new()

bucket = s3.buckets['pangea-data']

prefix = ARGV[0] + '/images'
prefix += '/' + ARGV[1] unless ARGV[1].nil?
ci_object_collection = bucket.objects.with_prefix(prefix)

if !File.exist?('index.html')
  puts "What?! No index.html?! Boo!"
  exit
end

@page = Nokogiri::HTML(open("#{File.expand_path(File.dirname(File.dirname(__FILE__)))}/index.html"))
tableElement = @page.at_css "tbody"

objectHash = getObjectHash(ci_object_collection)

objectHash.keys.sort.reverse_each do |key|
  myObject = objectHash[key]

  tableEntry = Nokogiri::XML::Node.new "tr", @page
  tableEntry.parent = tableElement

  tableEntryKey = Nokogiri::XML::Node.new "td", @page
  tableEntryKey.content = key
  tableEntryKey.parent = tableEntry

  directLinkValue = Nokogiri::XML::Node.new "td", @page
  directLinkValue.parent = tableEntry

  torrentLinkValue = Nokogiri::XML::Node.new "td", @page
  torrentLinkValue.parent = tableEntry

  if myObject.has_key? (:i386)
    directLink = Nokogiri::XML::Node.new "a", @page
    directLink['href'] = myObject[:i386]
    directLink.content = "[i386]"
    directLink.parent = directLinkValue

    torrentLink = Nokogiri::XML::Node.new "a", @page
    torrentLink['href'] = myObject[:i386] + "?torrent"
    torrentLink.content = "[i386]"
    torrentLink.parent = torrentLinkValue
  end

  if myObject.has_key?(:amd64)
    directLink = Nokogiri::XML::Node.new "a", @page
    directLink['href'] = myObject[:amd64]
    directLink.content = "[amd64]"
    directLink.parent = directLinkValue

    torrentLink = Nokogiri::XML::Node.new "a", @page
    torrentLink['href'] = myObject[:amd64] + "?torrent"
    torrentLink.content = "[amd64]"
    torrentLink.parent = torrentLinkValue
  end
end

puts @page.to_html
