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
          # In the before, the time is set to a VERY early time - so if it's within 5 seconds then we're good
          (Time.parse(json_data['time']) - Time.now).abs.should < 5
        end

        it 'handles a connection refused error by returning the cached data' do
          @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
          edc = ExternalDocumentCache.new(@pathname)
          Net::HTTP.should_receive(:start).and_raise(Errno::ECONNREFUSED)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 'handles a connection refused error by logging a warning' do
          @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
          Crichton.logger.should_receive(:warn).with("Log connection refused: #{@link}")
          edc = ExternalDocumentCache.new(@pathname)
          Net::HTTP.should_receive(:start).and_raise(Errno::ECONNREFUSED)
          edc.get(@link)
        end

        it 'handles other errorsby returning the cached data' do
          @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
          edc = ExternalDocumentCache.new(@pathname)
          Net::HTTP.should_receive(:start).and_raise(Errno::EADDRINUSE)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 'handles other errorsby returning the cached data' do
          @datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          File.open(@datafilename, 'wb') { |f| f.write("Testfile #{@link}") }
          Crichton.logger.should_receive(:warn).with("Address already in use while getting #{@link}")
          edc = ExternalDocumentCache.new(@pathname)
          Net::HTTP.should_receive(:start).and_raise(Errno::EADDRINUSE)
          edc.get(@link)

        end

      end

      context 'metadata with cache control' do
        it 'accepts data that is new enough' do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {'cache-control' => ['max-age=20']},
              time: Time.now - 2}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
          edc = ExternalDocumentCache.new(@pathname)
          Net::HTTP.should_not_receive(:start)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 're-validated data that is too old' do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {'cache-control' => ['max-age=20']},
              time: Time.now - 30}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          Net::HTTP.should_receive(:start).and_return(response)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 're-validated data that young enough but has the must-revalidate header set' do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {'cache-control' => ['max-age=200, must-revalidate']},
              time: Time.now - 30}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          Net::HTTP.should_receive(:start).and_return(response)
          edc.get(@link).should == "Testfile #{@link}"
        end

        it 're-validated data that young enough but has the no-cache header set' do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {'cache-control' => ['max-age=200, no-cache']},
              time: Time.now - 30}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          Net::HTTP.should_receive(:start).and_return(response)
          edc.get(@link).should == "Testfile #{@link}"
        end
      end

      context 'with custom metadata' do
        it 'sends the ETAG along in the request' do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {'etag' => ['1234']},
              time: Time.now - 100000}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          req = {}
          Net::HTTP::Get.stub(:new).and_return(req)
          Net::HTTP.stub(:start).and_return(response)
          edc.get(@link)
          req.should == { "If-None-Match" => "1234"}
        end

        it 'sends the last modified along in the request' do
          new_metadata = {
              link: @link,
              status: 200,
              headers: {'last-modified' => ['1234']},
              time: Time.now - 100000}
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.open(@metafilename, 'wb') { |f| f.write(new_metadata.to_json) }
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('304')
          req = {}
          Net::HTTP::Get.stub(:new).and_return(req)
          Net::HTTP.stub(:start).and_return(response)
          edc.get(@link)
          req.should == { "If-Modified-Since" => "1234"}
        end

        it 'in case of a cache miss, writes the received data to the cache' do
          @pathname = File.join('spec', 'fixtures', 'external_documents_cache')
          FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
          @metafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.meta.json")
          File.delete(@metafilename) if File.exist?(@metafilename)
          #@datafilename = File.join(@pathname, "#{Digest::MD5.hexdigest(@link)}.cache")
          #File.delete(@datafilename) if File.exist?(@datafilename)
          edc = ExternalDocumentCache.new(@pathname)
          response = double('response')
          response.stub(:code).and_return('200')
          response.stub(:body).and_return('Data')
          headers = double('headers')
          headers.stub('to_hash').and_return({'Headers' => 'Headerdata'})
          response.stub(:to_hash).and_return(headers)
          Net::HTTP.stub(:start).and_return(response)
          edc.get(@link)
          json_data = JSON.parse(File.open(@metafilename, 'rb') { |f| f.read })
          json_data.should include(
            {
              "link" => "http://some.url:1234/somepath",
              "status" => "200",
              "headers" => {"Headers" => "Headerdata"}
            })
        end
      end
    end
  end
end
