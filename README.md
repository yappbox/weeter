Weeter is a tireless worker who accepts a set of Twitter users to follow and terms to track, subscribes using Twitter's streaming API, and notifies your app with each new tweet (or tweet deletion).

Supported strategies for tweet notification include HTTP (issue a POST to your app) and Resque (queue a job). Weeter is extensible with other notification strategies.

Status
======
Alpha. A previous version of this code has been in production for some time. It has been substantially refactored and will be battle-tested soon.

[![Build Status](https://secure.travis-ci.org/lukemelia/weeter.png?branch=master)](http://travis-ci.org/lukemelia/weeter)

Getting set up
==============

    $ bundle install

Make a copy of the weeter.conf.example file named weeter.conf. Twitter configuration, client app configuration and weeter configuration are defined in separate
blocks. To configure how you connect to Twitter (basic auth or oauth), modify the twitter section of the configuration.

To configure how weeter connects to your client app, modify the client app configuration section:

Notifications
-------------

* *notification_plugin*: A symbol matching the underscorized name of the NotificationPlugin subclass to use. Current options are :http and :resque

For option :http, also provide the following:

* *oauth*: See the conf file for an example

* *publish_url*: The URL to which new tweets should be posted. Request will be sent with POST method. Example body:
    `id=1111&twitter_user_id=19466709&text=Wassup`
* *delete_url*: The URL to which data about deleted tweets should be posted. Request will be sent with DELETE method. Example body:
    `id=1111&twitter_user_id=19466709`

For option :resque, provide the following:

* *queue*: Name of the queue to add the job to

* *redis_uri*: Redis connection string

Subscriptions
-------------

* *subscription_plugin*: A symbol matching the underscorized name of the SubscrptionsPlugin subclass to use. Current options are :http and :redis

For option :http, also provide the following:

* *oauth*: See the conf file for an example

* *subscriptions_url*: The URL at which to find JSON describing the Twitter users to follow (maximum 5,000 at the default API access level) and the terms to track (maximum 400 at the default API access level). Example content:
    `{"follow":["19466709", "759251"],"track":["#lolcats","#bieber"]}`

* *subscription_updates_port*: The port Weeter should listen on for HTTP connections. If you have changes to your subscriptions data, POST the full JSON to the weeter's root URL. This will trigger weeter to reconnect to Twitter with the updated filters in place.

For option :redis, also provide the following:

* *subscriptions_key*: The Redis key at which the Weeter can find JSON describing the Twitter users to follow (maximum 5,000 at the default API access level) and the terms to track (maximum 400 at the default API access level). Example content:
    `{"follow":["19466709", "759251"],"track":["#lolcats","#bieber"]}`

* *subscriptions_changed_channel*: The Redis publish/subscribe channel to subscribe to in order to be notified that the subscriptions have changed. When your app has an updated set of subscriptions, it should update the _subscriptions_key_ and publish a "CHANGED" message to this channel. Weeter will then retrieve an updated set of subscriptions from Redis and reconnect to twitter.

* *redis_uri*: Redis connection string

Rate Limiting
-------------

If you track high-volume hashtags, it's easy to bite off more than your infrastructure can chew. To help with this situation, Weeter has basic rate-limiting built-in. You can enable it and configure a max and time period in your conf file (see weeter.conf.example for syntax). If the max is reached in a given period, additional tweets with that hashtag that come in during the time period will be logged and discarded. New tweets will begin being allowed through at the beginning of the subsequent period.

Running weeter
==============

Weeter can be run using the weeter executable installed by the gem.

Running Weeter as a daemon
--------------------------
The gem also installs a weeter_control executable that can be used to start Weeter as a daemon

    $ bin/weeter_control start

This starts Weeter as a daemon. For other commands and options, run:

    $ bin/weeter_control --help



Running specs
=============

    $ bundle exec rspec spec/

TODO
====
- Better error reporting
- Make tweet filtering strategy (re-tweets, replies, etc.) more configurable
- Add specs for plugins
- Extract plugins into separate gems
- integration tests

Credits
======
Thanks to Weplay for initial development and open sourcing Weeter. In particular, credit goes to Noah Davis and Joey Aghion. Further development by Luke Melia at Yapp.

License
=======
Weeter is available under the terms of the MIT License http://www.opensource.org/licenses/mit-license.php
