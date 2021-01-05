require 'terrapin'
require 'mail'
require 'time'

module Email2nc
  class MailHandler

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
        STDERR.puts "Error: mail is missing attachements"
      end
    end

    def send_to_nextcloud(attachments)
      cmd   = '/usr/bin/curl'
      month = Time.now.month
      attachments.each do |attachment|
        # create base folder
        path    = "#{NC_URL}/remote.php/dav/files/#{NC_USERNAME}/#{NC_FOLDER}"
        options = %[-s -u :credentials -X MKCOL ':path']
        args    = { credentials: credentials, path: path }
        execute(cmd, options, args)
        # create month folder
        path    = "#{NC_URL}/remote.php/dav/files/#{NC_USERNAME}/#{month}"
        options = %[-s -u :credentials -X MKCOL ':path']
        args    = { credentials: credentials, path: path }
        execute(cmd, options, args)
        # upload attachement
        path    = "#{NC_URL}/remote.php/dav/files/#{NC_USERNAME}/#{month}/#{File.basename(attachement)}"
        options = %[-s -u :credentials -T ':attachment' ':path']
        args    = { credentials: credentials, attachment: attachment, path: path }
        execute(cmd, options, args)
      end
    end

    def remove(attachments)
      attachments.each { |attachment| File.delete(attachment) if File.exist?(attachment) }
    end

    private

    def credentials
      "#{ENV['NC_USERNAME']}#{ENV['NC_PASSWORD']}"
    end

    def execute(cmd, options="", args={})
      line = Terrapin::CommandLine.new(
        cmd,
        options,
        expected_outcodes: [0,1],
        logger: nil
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