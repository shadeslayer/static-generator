#!/usr/bin/ruby
require 'aws'
require 'nokogiri'
require 'date'

def getObjectHash(objectCollection)
  objectHash = {}
  objectCollection.each do |object|
    if object.key.end_with? ".iso"
      tempHash = {}
      fileName = object.key.split('/').last
      date = Date.parse(fileName.split('-')[2])
      if fileName.include? 'amd64'
        tempHash = { date => {:amd64 => "http://pangea-data.s3.amazonaws.com/" + object.key }}
      end
      if fileName.include? 'i386'
        tempHash = { date => {:i386 => "http://pangea-data.s3.amazonaws.com/" + object.key }}
      end
      ## Merge the arch hash inside of hash instead of overwriting it
      objectHash.merge!(tempHash) { |key, oldval, newval| newval.merge!(oldval) }
    end
  end
  return objectHash
end

unless ARGV[0]
  puts "What do you think you're trying to pull mister!"
  exit
end

s3 = AWS::S3.new()

bucket = s3.buckets['pangea-data']

kci_object_collection = bucket.objects.with_prefix(ARGV[0] + "/images")

if !File.exist?('index.html')
  puts "What?! No index.html?! Boo!"
end

@page = Nokogiri::HTML(open("index.html"))
tableElement = @page.at_css "tbody"

objectHash = getObjectHash(kci_object_collection)

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
