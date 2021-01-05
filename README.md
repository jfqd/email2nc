# Email2nc

Send pdf-documents in emails fetched via imap to a given nextcloud-instance.

## Installation

```
git clone https://github.com/jfqd/email2nc.git
cd email2nc
gem build email2nc.gemspec

gem install dotenv
gem install terrapin
gem install mail
gem install --local email2nc-*.gem

cp env.sample ../
cd ..
rm -rf email2nc

mkdir email2nc
mv env.sample email2nc/.env
cd email2nc
echo 'gem "email2nc"' > Gemfile
bundle install --binstubs
```

## Usage

Add a cronjob to execute the script

```
*/5 * * * * cd /home/jerry/email2nc && ./bin/email2nc
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Copyright (c) 2021 qutic development GmbH