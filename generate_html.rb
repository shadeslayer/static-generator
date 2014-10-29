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
      if fileName.include? 'amd64'
        fileName = fileName.split('-amd64').first[0...-4]
        tempHash = { fileName => {:amd64 => "http://pangea-data.s3.amazonaws.com/" + object.key }}
      end
      if fileName.include? 'i386'
        fileName = fileName.split('-i386').first[0...-4]
        tempHash = { fileName => {:i386 => "http://pangea-data.s3.amazonaws.com/" + object.key }}
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

@page = Nokogiri::HTML(open("index.html"))
tableElement = @page.at_css "tbody"

objectHash = getObjectHash(kci_object_collection)

## Ruby is weird here, I don't totally understand why, but
## we get a array after this pass.

objectHash = objectHash.sort_by { |k, v| Date.parse(k.split('-').last) }

objectHash.reverse_each do |key|
  myObject = key[1]

  tableEntry = Nokogiri::XML::Node.new "tr", @page
  tableEntry.parent = tableElement

  tableEntryKey = Nokogiri::XML::Node.new "td", @page
  tableEntryKey.content = key[0]
  tableEntryKey.parent = tableEntry

  directLinkValue = Nokogiri::XML::Node.new "td", @page
  directLinkValue.parent = tableEntry

  torrentLinkValue = Nokogiri::XML::Node.new "td", @page
  torrentLinkValue.parent = tableEntry

  zsyncLinkValue = Nokogiri::XML::Node.new "td", @page
  zsyncLinkValue.parent = tableEntry

  if myObject.has_key? (:i386)
    directLink = Nokogiri::XML::Node.new "a", @page
    directLink['href'] = myObject[:i386]
    directLink.content = "[i386]"
    directLink.parent = directLinkValue

    torrentLink = Nokogiri::XML::Node.new "a", @page
    torrentLink['href'] = myObject[:i386] + "?torrent"
    torrentLink.content = "[i386]"
    torrentLink.parent = torrentLinkValue

    zsyncLink = Nokogiri::XML::Node.new "a", @page
    zsyncLink['href'] = myObject[:i386] + ".zsync"
    zsyncLink.content = "[i386]"
    zsyncLink.parent = zsyncLinkValue

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

    zsyncLink = Nokogiri::XML::Node.new "a", @page
    zsyncLink['href'] = myObject[:amd64] + ".zsync"
    zsyncLink.content = "[amd64]"
    zsyncLink.parent = zsyncLinkValue
  end
end

puts @page.to_html