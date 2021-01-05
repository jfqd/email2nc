require 'terrapin'
require 'mail'
require 'time'
require 'logger'

module Email2nc
  class MailHandler

    LOGGER = ( ENV['DEBUG'] == 'true' ? Logger.new(STDERR) : nil )

    def self.receive(raw_mail)
      raw_mail.force_encoding('ASCII-8BIT') if raw_mail.respond_to?(:force_encoding)
      email = Mail.new(raw_mail)
      new.receive(email)
    end

    def self.safe_receive(*args)
      receive(*args)
    rescue Exception => e
      STDERR.puts "Error: an unexpected error occurred when receiving email: #{e.message}"
      return false
    end

    def receive(email)
      attachments = []
      if email.attachments && email.attachments.any?
        email.attachments.each do |attachment|
          name = attachment.filename.to_s.gsub(" ","-")
          file = "#{ENV['TMP'] || '/var/tmp' }/#{name}"
          next unless name =~ /\A.*\.pdf\z/i
          File.open(file, "w") {|f| f.write( attachment.body.decoded ) }
          attachments << file
        end
        send_to_nextcloud(attachments)
        remove(attachments)
        return true
      else
        STDERR.puts "Error: mail is missing attachments"
      end
    end

    def send_to_nextcloud(attachments)
      cmd   = '/usr/bin/curl'
      month = "0#{Time.now.month}"[-2..-1]
      year  = Time.now.year
      basefolder ="#{username}/#{folder}"

      puts "create base folder" if ENV['DEBUG']
      path    = "#{nextcloud_url}/remote.php/dav/files/#{basefolder}"
      options = %[-s -u :credentials -X MKCOL :path]
      args    = { credentials: credentials, path: path }
      execute(cmd, options, args)
      
      puts "create year folder" if ENV['DEBUG']
      path    = "#{nextcloud_url}/remote.php/dav/files/#{basefolder}/#{year}"
      options = %[-s -u :credentials -X MKCOL :path]
      args    = { credentials: credentials, path: path }
      
      puts "create month folder" if ENV['DEBUG']
      path    = "#{nextcloud_url}/remote.php/dav/files/#{basefolder}/#{year}/#{month}"
      options = %[-s -u :credentials -X MKCOL :path]
      args    = { credentials: credentials, path: path }
      execute(cmd, options, args)
      
      puts "upload attachments" if ENV['DEBUG']
      attachments.each do |attachment|
        path    = "#{nextcloud_url}/remote.php/dav/files/#{basefolder}/#{year}/#{month}/#{File.basename(attachment)}"
        options = %[-s -u :credentials -T :attachment :path]
        args    = { credentials: credentials, attachment: attachment, path: path }
        execute(cmd, options, args)
      end
    end

    def remove(attachments)
      attachments.each { |attachment| File.delete(attachment) if File.exist?(attachment) }
    end

    private

    def nextcloud_url
      ENV['NC_URL']
    end

    def credentials
      "#{username}:#{ENV['NC_PASSWORD']}"
    end

    def username
      ENV['NC_USERNAME']
    end

    def folder
      ENV['NC_FOLDER']
    end

    def execute(cmd, options="", args={})
      line = Terrapin::CommandLine.new(
        cmd,
        options,
        expected_outcodes: [0,1],
        logger: LOGGER
      )
      begin
        return line.run(args)
      rescue Terrapin::ExitStatusError => e
        STDERR.puts "Error: #{e.message}"
        return nil
      rescue Terrapin::CommandNotFoundError => e
        STDERR.puts "Error: #{e.message}"
        return nil
      end
    end

  end
end