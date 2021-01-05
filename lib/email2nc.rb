require "email2nc/version"
require "email2nc/imap"

module Email2nc
  class Error < StandardError; end

  class CLI
    def call(*args)
      # todo: setup printer
      # fetch imap
      imap_options = {
        :host => ENV['IMAP_HOST'],
        :port => ENV['IMAP_PORT'],
        :ssl  => (ENV['SSL'] == 'true'),
        :username => ENV['USERNAME'],
        :password => ENV['PASSWORD'],
        :folder   => ENV['FOLDER'],
        :move_on_success => ENV['MOVE_ON_SUCCESS'],
        :move_on_failure => ENV['MOVE_ON_FAILURE']
      }
      Email2nc::IMAP.check(imap_options)
    end
  end
end
