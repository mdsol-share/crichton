require 'json'
require 'spec_helper'
require 'fileutils'

module Crichton
  describe 'ExternalDocumentCache' do
    context '.new' do
      it 'accepts a cache path' do
        pathname = 'test/path'
        Dir.should_receive(:exists?).with(pathname).and_return(true)
        ExternalDocumentCache.new(pathname)
      end

      it 'uses the configured cache path if none is explicitly passed into the new call' do
        pathname = 'test/path'
        Crichton.config.stub(:external_documents_store_directory).and_return(pathname)
        Dir.should_receive(:exists?).with(pathname).and_return(true)
        ExternalDocumentCache.new(pathname)
      end

      it 'creates the cache path if it does not exist' do
        pathname = 'test/path'
        Dir.stub(:exists?).and_return(false)
        FileUtils.should_receive(:mkdir_p).with(pathname).and_return(true)
        ExternalDocumentCache.new(pathname)
      end
    end

    context '.get' do
      before do
        @pathname = File.join('spec', 'fixtures', 'external_documents_cache')
        FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
        @link = 'http://some.url:1234/somepath'
        @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
        File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
      end

      context 'in the basic case' do
        before do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {},
              time: Time.now + 1000}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
        end

        it 'reads the data file and returns the data' do
          edc = ExternalDocumentCache.new(@pathname)
          edc.get(@link).should == "Testfile #{@link}"
        end
      end

      context 'in case of outdated metadata' do
        before do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {},
              time: Time.now - 100000}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
        end

        it 'tries to verify the data and accepts a 304 response' do
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          Net::HTTP.should_receive(:start).and_return(response)
          edc.get(@link)
        end

        it 'tries to verify the data and returns the data from the file in case of a 304' do
          @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          Net::HTTP.should_receive(:start).and_return(response)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 'tries to verify the data and returns the data from the file in case of a 404' do
          @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('404')
          Net::HTTP.should_receive(:start).and_return(response)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 'tries to verify the data and updates the metadata in the file' do
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          Net::HTTP.stub(:start).and_return(response)
          edc.get(@link)
          json_data = JSON.parse(File.open(@metafilename, 'rb') { |f| f.read })
          # In the befoer, the time is set to a VERY early time - so if it's within 5 seconds then we're good
          (Time.parse(json_data['time']) - Time.now).abs.should < 5
        end

        # TODO: Add miss and write case
        # TODO: Add Etag case of conditional GET
        # TODO: Add Last-Modified case of conditional GET
      end
    end
  end
end
