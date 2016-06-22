require 'openssl'
require 'json'
require 'fileutils'

module DirectoryDigest
  # DirectoryDigest::Digest - Creates a SHA256 digest of a directory's content
  class Digest
    attr_reader :directory
    attr_reader :directory_digest
    attr_reader :file_digests

    def initialize(directory, directory_digest, file_digests)
      @directory = directory
      @directory_digest = directory_digest
      @file_digests = file_digests
    end

    def self.sha256(directory, glob = '**/*', includes = [])
      FileUtils.makedirs(directory) unless Dir.exist?(directory)
      directory_digest = OpenSSL::Digest::SHA256.new
      file_digests = {}
      Dir["#{directory}/#{glob}"].each do |filename|
        next unless File.file?(filename)
        path = filename[directory.size, 99_999]
        included = true
        includes.each do |include|
          included = include[0] == '+' if include.size > 1 && path =~ /#{include[1, 99_999]}/i
        end
        next unless included
        file_digest = OpenSSL::Digest::SHA256.new
        File.open(filename, 'rb') do |file|
          until file.eof?
            chunk = file.read(4096)
            directory_digest << chunk
            file_digest << chunk
          end
        end
        file_digests[path] = file_digest.hexdigest
      end
      Digest.new(directory, directory_digest.hexdigest, file_digests)
    end

    def ==(other)
      directory_digest == other.directory_digest
    end

    def !=(other)
      directory_digest != other.directory_digest
    end

    def changes_relative_to(other)
      {
        added: file_digests.select { |path, _| !other.file_digests.key?(path) },
        removed: other.file_digests.select { |path, _| !file_digests.key?(path) },
        changed: other.file_digests.select { |path, digest| file_digests.key?(path) && digest != file_digests[path] },
        unchanged: other.file_digests.select { |path, digest| file_digests.key?(path) && digest == file_digests[path] }
      }
    end

    def mirror_from(other, actions = MirrorActions.new)
      files_copied = 0
      files_deleted = 0
      changes = changes_relative_to(other)
      changes[:removed].merge(changes[:changed]).each do |path, _|
        source_path = "#{other.directory}#{path}"
        destination_path = "#{directory}#{path}"
        destination_directory = File.dirname(destination_path)
        actions.create_directory(destination_directory) unless Dir.exist?(destination_directory)
        actions.copy_file(source_path, destination_path)
        files_copied += 1
      end
      changes[:added].each do |path, _|
        actions.delete_file("#{directory}#{path}")
        files_deleted += 1
      end
      { files_copied: files_copied, files_deleted: files_deleted }
    end

    def to_json
      JSON.pretty_generate(directory: directory, directory_digest: directory_digest, file_digests: file_digests)
    end

    def self.from_json(json)
      json = JSON.parse(json)
      Digest.new(json['directory'], json['directory_digest'], json['file_digests'])
    end
  end

  # DirectoryDigest::MirrorActions - Provider for standard mirror making activities
  class MirrorActions
    def create_directory(directory)
      FileUtils.makedirs(directory)
    end

    def copy_file(source, destination)
      File.open(source, 'rb') do |source_file|
        File.open(destination, 'wb') do |destination_file|
          destination_file.write(source_file.read(4096)) until source_file.eof?
        end
      end
    end

    def delete_file(filename)
      File.delete(filename)
    end
  end
end
