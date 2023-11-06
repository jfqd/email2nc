require 'net/imap'
require 'email2nc/mail_handler'

module Email2nc
  module IMAP
    class << self

      def check(imap_options={})
        host            = imap_options[:host]   || '127.0.0.1'
        port            = imap_options[:port]   || '993'
        ssl             = imap_options[:ssl]    || false
        folder          = imap_options[:folder] || 'INBOX'
        move_on_failure = imap_options[:move_on_failure] || 'failure'
        move_on_success = imap_options[:move_on_success] || 'success'
        return if imap_options[:username].nil? || imap_options[:password].nil?
        imap = Net::IMAP.new(host, port: port, ssl: ssl)
        imap.login(imap_options[:username], imap_options[:password])
        imap.select(folder)
        imap.search(['NOT', 'SEEN']).each do |message_id|
          msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
          if MailHandler.safe_receive(msg)
            imap.copy(message_id, move_on_success) if move_on_success
            imap.store(message_id, "+FLAGS", [:Seen, :Deleted])
          else
            imap.store(message_id, "+FLAGS", [:Seen])
            if move_on_failure
              imap.copy(message_id, move_on_failure)
              imap.store(message_id, "+FLAGS", [:Deleted])
            end
          end
        end
        imap.expunge
        imap.logout
        imap.disconnect
      end # check(imap_options={})

    end # class << self
  end # IMAP
end # Email2nc
