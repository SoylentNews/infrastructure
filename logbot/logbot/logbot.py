#!/usr/bin/env python2
# coding: utf-8

"""
   LogBot

   A minimal IRC log bot

   Written by Chris Oliver

   Includes python-irclib from http://python-irclib.sourceforge.net/

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA   02111-1307, USA.
"""


__author__ = "Chris Oliver <excid3@gmail.com>"
__version__ = "0.4.2"
__date__ = "08/11/2009"
__copyright__ = "Copyright (c) Chris Oliver"
__license__ = "GPL2"


import cgi
import os
import ftplib
import sys
import itertools
from time import strftime
try:
    from datetime import datetime
    from pytz import timezone
except: pass

try:
    from hashlib import md5
except:
    import md5

from ircbot import SingleServerIRCBot
from irclib import nm_to_n

import re
import json

pat1 = re.compile(r"(^|[\n ])(([\w]+?://[\w\#$%&~.\-;:=,?@\[\]+]*)(/[\w\#$%&~/.\-;:=,?@\[\]+]*)?)", re.IGNORECASE | re.DOTALL)

#urlfinder = re.compile("(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'\".,<>?«»“”‘’]))")

def urlify2(value):
    return pat1.sub(r'\1<a href="\2" target="_blank">\3</a>', value)
    #return urlfinder.sub(r'<a href="\1">\1</a>', value)

### Configuration options
DEBUG = False

# IRC Server Configuration
SERVER = os.environ.get('LOGGIE_IRCSERVER', "localhost")
PORT = int(os.environ.get('LOGGIE_IRCPORT', 6667))
SERVER_PASS = os.environ.get('LOGGIE_IRCPASS', None)
CHANNELS = json.loads(os.environ.get('LOGGIE_CHANNELS', '[]'))
NICK = os.environ.get('LOGGIE_IRCNICK', 'LoggieStaging')
NICK_PASS = os.environ.get('LOGGIE_NICKPASS','soylent')

# The local folder to save logs
LOG_FOLDER = "/logs"

# The message returned when someone messages the bot
HELP_MESSAGE = "Check out http://logs.sylnt.us/"

# FTP Configuration
FTP_SERVER = ""
FTP_USER = ""
FTP_PASS = ""
# This folder and sub folders for any channels MUST be created on the server
FTP_FOLDER = ""
# The amount of messages to wait before uploading to the FTP server
FTP_WAIT = 25

CHANNEL_LOCATIONS_FILE = os.path.expanduser("/config/.logbot-channel_locations.conf")
DEFAULT_TIMEZONE = 'UTC'

default_format = {
    "help" : HELP_MESSAGE,
    "action" : '<span class="person" style="color:%color%">* %user% %message%</span>',
    "join" : '-!- <span class="join">%user%</span> [%host%] has joined %channel%',
    "kick" : '-!- <span class="kick">%user%</span> was kicked from %channel% by %kicker% [%reason%]',
    "mode" : '-!- mode/<span class="mode">%channel%</span> [%modes% %person%] by %giver%',
    "nick" : '<span class="nick">%old%</span> is now known as <span class="nick">%new%</span>',
    "part" : '-!- <span class="part">%user%</span> [%host%] has parted %channel%',
    "pubmsg" : '<span class="person" style="color:%color%">&lt;%user%&gt;</span> %message%',
    "pubnotice" : '<span class="notice">-%user%:%channel%-</span> %message%',
    "quit" : '-!- <span class="quit">%user%</span> has quit [%message%]',
    "topic" : '<span class="topic">%user%</span> changed topic of <span class="topic">%channel%</span> to: %message%',
}

html_header = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>%title%</title>
    <style type="text/css">
        body {
            background-color: #F8F8FF;
            font-family: Fixed, monospace;
            font-size: 13px;
        }
        h1 {
            font-family: sans-serif;
            font-size: 24px;
            text-align: center;
        }
        a, .time {
            color: #525552;
            text-decoration: none;
        }
        a:hover, .time:hover { text-decoration: underline; }
        .person { color: #DD1144; }
        .join, .part, .quit, .kick, .mode, .topic, .nick { color: #42558C; }
        .notice { color: #AE768C; }
    </style>
<script>
        function checkAndReload() {
           if (window.scrollY === 0) {
             console.log('Page is not scrolled, reloading...');
             window.location.reload();
           } else {
             console.log('Page is scrolled, not reloading.');
           }
         }
       function reverseNodes() {
         const bodyChildNodes = Array.from(document.body.childNodes).slice(5); // Skip the first three nodes (h1 and return link)

         if (bodyChildNodes.every((child, index) => (index % 2 === 0 && child.nodeType === Node.ELEMENT_NODE && child.tagName.toLowerCase() === 'a') || (index % 2 === 1 && child.nodeType === Node.ELEMENT_NODE && child.tagName.toLowerCase() === 'br'))) {
           // Case 1: All links with dates followed by <br>
           const pairs = [];
           for (let i = 0; i < bodyChildNodes.length; i += 2) {
             pairs.push([bodyChildNodes[i], bodyChildNodes[i + 1]]);
           }
           pairs.reverse();
           bodyChildNodes.length = 0;
           pairs.forEach(pair => bodyChildNodes.push(...pair));
         } else {
           // Case 2: Grouped entries until the next <br>
           const groups = [];
           let currentGroup = [];
           bodyChildNodes.forEach(node => {
             currentGroup.push(node);
             if (node.nodeType === Node.ELEMENT_NODE && node.tagName.toLowerCase() === 'br') {
               groups.push(currentGroup);
               currentGroup = [];
             }
           });
           if (currentGroup.length > 0) {
             groups.push(currentGroup);
           }
           groups.reverse();
           bodyChildNodes.length = 0;
           groups.forEach(group => bodyChildNodes.push(...group));
         }

         // Clear and re-append reversed nodes
         const parent = document.body;
         bodyChildNodes.forEach(child => parent.appendChild(child));
       }

       document.addEventListener('DOMContentLoaded', function() {
         reverseNodes(); // Initial call
         setInterval(checkAndReload, 10000); // Call every 10 seconds
       });
 </script>

  </head>
  <body>
  <h1>%title%</h1>
  <a href="..">&laquo; return</a><br />
  </body>
</html>
"""


### Helper functions

def append_line(filename, line):
    data = open(filename, "rb").readlines()[:-2]
    data += [line, "\n<br />", "\n</body>", "\n</html>"]
    write_lines(filename, data)

def write_lines(filename, lines):
    f = open(filename, "wb")
    f.writelines(lines)
    f.close()

def write_string(filename, string):
    f = open(filename, "wb")
    f.write(string)
    f.close()

color_pattern = re.compile(r'(\[\d{1,2}m)')
"Pattern that matches ANSI color codes and the text that follows"

def pairs(items):
    """
    Return pairs from items

    >>> list(pairs([1,2,3,4]))
    [(1, 2), (3, 4)]
    """
    items = iter(items)
    while True:
        yield next(items), next(items)

def html_color(input):
    """
    >>> html_color("This is plain but [30m this is in color")
    'This is plain but <span style="color: #000316"> this is in color</span>'
    >>> html_color("[32mtwo[37mcolors")
    '<span style="color: #00aa00">two</span><span style="color: #F5F1DE">colors</span>'
    """
    first = []
    parts = color_pattern.split(input)
    if len(parts) % 2:
        # an odd number of parts occurred - first part is uncolored
        first = [parts.pop(0)]
    rest = itertools.starmap(replace_color, pairs(parts))
    return ''.join(itertools.chain(first, rest))

def replace_color(code, text):
    code = code.lstrip('[').rstrip('m')
    colors = {
        '30': '000316',
        '31': 'aa0000',
        '32': '00aa00',
        '33': 'aa5500',
        '34': '0000aa',
        '35': 'E850A8',
        '36': '00aaaa',
        '37': 'F5F1DE',
    }
    if code not in colors:
        return text
    return '<span style="color: #%(color)s">%(text)s</span>' % dict(
        color = colors[code],
        text = text,
    )


### Logbot class

class Logbot(SingleServerIRCBot):
    def __init__(self, server, port, server_pass=None, channels=[],
                 nick="timber", nick_pass=None, format=default_format):
        SingleServerIRCBot.__init__(self,
                                    [(server, port, server_pass)],
                                    nick,
                                    "bot")

        self.chans = [x.lower() for x in channels]
        self.format = format
        self.set_ftp()
        self.count = 0
        self.nick_pass = nick_pass
        
        # Channel retry mechanism
        self.pending_channels = list(self.chans)  # Channels to join
        self.failed_channels = {}  # Failed channels with retry count
        self.max_retries = 3
        self.retry_delays = [30, 60, 120]  # Retry after 30s, 60s, 120s
        self.nickserv_delay = 3  # Wait 3 seconds after NickServ auth
        self.nickserv_authenticated = False
        
        self.load_channel_locations()
        print "Logbot %s" % __version__
        print "Connecting to %s:%i..." % (server, port)
        print "Press Ctrl-C to quit"

    def quit(self):
        self.connection.disconnect("Quitting...")

    def color(self, user):
        return "#%s" % md5(user).hexdigest()[:6]

    def set_ftp(self, ftp=None):
        self.ftp = ftp

    def format_event(self, name, event, params):
        msg = self.format[name]
        for key, val in params.iteritems():
            msg = msg.replace(key, val)

        # Always replace %user% with e.source()
        # and %channel% with e.target()
        msg = msg.replace("%user%", nm_to_n(event.source()))
        msg = msg.replace("%host%", event.source())
        try: msg = msg.replace("%channel%", event.target())
        except: pass
        msg = msg.replace("%color%", self.color(nm_to_n(event.source())))
        try:
            user_message = cgi.escape(event.arguments()[0])
            msg = msg.replace("%message%", html_color(user_message))
        except: pass

        return msg

    def write_event(self, name, event, params={}):
        # Format the event properly
        if name == 'nick' or name == 'quit':
          chans = params["%chan%"]
        else:
          chans = event.target()
        msg = self.format_event(name, event, params)
        msg = urlify2(msg)

        # In case there are still events that don't supply a channel name (like /quit and /nick did)
        if not chans or not chans.startswith("#"):
            chans = self.chans
        else:
            chans = [chans]

        for chan in chans:
            self.append_log_msg(chan, msg)

        self.count += 1

        if self.ftp and self.count > FTP_WAIT:
            self.count = 0
            print "Uploading to FTP..."
            for root, dirs, files in os.walk("logs"):
                #TODO: Create folders

                for fname in files:
                    full_fname = os.path.join(root, fname)

                    if sys.platform == 'win32':
                        remote_fname = "/".join(full_fname.split("\\")[1:])
                    else:
                        remote_fname = "/".join(full_fname.split("/")[1:])
                    if DEBUG: print repr(remote_fname)

                    # Upload!
                    try: self.ftp.storbinary("STOR %s" % remote_fname, open(full_fname, "rb"))
                    # Folder doesn't exist, try creating it and storing again
                    except ftplib.error_perm, e: #code, error = str(e).split(" ", 1)
                        if str(e).split(" ", 1)[0] == "553":
                            self.ftp.mkd(os.path.dirname(remote_fname))
                            self.ftp.storbinary("STOR %s" % remote_fname, open(full_fname, "rb"))
                        else: raise e
                    # Reconnect on timeout
                    except ftplib.error_temp, e: self.set_ftp(connect_ftp())
                    # Unsure of error, try reconnecting
                    except:                      self.set_ftp(connect_ftp())

            print "Finished uploading"

    def append_log_msg(self, channel, msg):
        print "%s >>> %s" % (channel, msg)
        #Make sure the channel is always lowercase to prevent logs with other capitalisations to be created
        channel_title = channel
        channel = channel.lower()

        # Create the channel path if necessary
        chan_path = "%s/%s" % (LOG_FOLDER, channel)
        if not os.path.exists(chan_path):
            os.makedirs(chan_path)

            # Create channel index
            write_string("%s/index.html" % chan_path, html_header.replace("%title%", "%s | Logs" % channel_title))

            # Append channel to log index
            append_line("%s/index.html" % LOG_FOLDER, '<a href="%s/index.html">%s</a>' % (channel.replace("#", "%23"), channel_title))

        # Current log
        try:
            localtime = datetime.now(timezone(self.channel_locations.get(channel,DEFAULT_TIMEZONE)))
            time = localtime.strftime("%H:%M:%S")
            date = localtime.strftime("%Y-%m-%d")
        except:
            time = strftime("%H:%M:%S")
            date = strftime("%Y-%m-%d")

        log_path = "%s/%s/%s.html" % (LOG_FOLDER, channel, date)

        # Create the log date index if it doesnt exist
        if not os.path.exists(log_path):
            write_string(log_path, html_header.replace("%title%", "%s | Logs for %s" % (channel_title, date)))

            # Append date log
            append_line("%s/index.html" % chan_path, '<a href="%s.html">%s</a>' % (date, date))

        # Append current message
        message = "<a href=\"#%s\" name=\"%s\" class=\"time\">[%s]</a> %s" % \
                                          (time, time, time, msg)
        append_line(log_path, message)

    ### These are the IRC events

    def on_all_raw_messages(self, c, e):
        """Display all IRC connections in terminal"""
        if DEBUG: print e.arguments()[0]

    def on_welcome(self, c, e):
        """Join channels after successful connection"""
        print "Connected to server, authenticating..."
        
        if self.nick_pass:
            print "Authenticating with NickServ..."
            c.privmsg("nickserv", "identify %s" % self.nick_pass)
            # Schedule delayed channel joining after NickServ auth
            self.connection.execute_delayed(self.nickserv_delay, self._join_pending_channels)
        else:
            # No NickServ auth needed, join immediately
            self._join_pending_channels()
    
    def _join_pending_channels(self):
        """Join all pending channels"""
        print "Joining %d channels..." % len(self.pending_channels)
        for chan in list(self.pending_channels):
            print "Joining channel: %s" % chan
            self.connection.join(chan)

    def _schedule_channel_retry(self, channel):
        """Schedule a retry for a failed channel join"""
        if channel not in self.failed_channels:
            self.failed_channels[channel] = 0
        
        retry_count = self.failed_channels[channel]
        
        if retry_count < self.max_retries:
            delay = self.retry_delays[min(retry_count, len(self.retry_delays) - 1)]
            self.failed_channels[channel] += 1
            
            print "Scheduling retry %d/%d for %s in %d seconds" % (
                retry_count + 1, self.max_retries, channel, delay)
            
            self.connection.execute_delayed(delay, lambda: self._retry_channel_join(channel))
        else:
            print "Max retries reached for channel: %s" % channel
            del self.failed_channels[channel]
    
    def _retry_channel_join(self, channel):
        """Retry joining a specific channel"""
        print "Retrying join for channel: %s" % channel
        self.connection.join(channel)

    def get_join_status(self):
        """Get current status of channel joins"""
        total_channels = len(self.chans)
        joined_channels = len([c for c in self.chans if c in self.channels])
        pending_channels = len(self.pending_channels)
        failed_channels = len(self.failed_channels)
        
        print "Channel Status: %d total, %d joined, %d pending, %d retrying" % (
            total_channels, joined_channels, pending_channels, failed_channels)
        
        if self.failed_channels:
            for channel, retry_count in self.failed_channels.items():
                print "  Retrying: %s (attempt %d/%d)" % (channel, retry_count, self.max_retries)

    # Error handlers for channel join failures
    def on_channelisfull(self, c, e):
        """Handle channel is full error (471)"""
        channel = e.arguments()[1].lower() if len(e.arguments()) > 1 else None
        if channel:
            print "Channel is full: %s" % channel
            self._schedule_channel_retry(channel)

    def on_inviteonlychan(self, c, e):
        """Handle invite only channel error (473)"""
        channel = e.arguments()[1].lower() if len(e.arguments()) > 1 else None
        if channel:
            print "Channel is invite only: %s" % channel
            self._schedule_channel_retry(channel)

    def on_bannedfromchan(self, c, e):
        """Handle banned from channel error (474)"""
        channel = e.arguments()[1].lower() if len(e.arguments()) > 1 else None
        if channel:
            print "Banned from channel: %s" % channel
            # Don't retry banned channels
            if channel in self.pending_channels:
                self.pending_channels.remove(channel)
            if channel in self.failed_channels:
                del self.failed_channels[channel]

    def on_badchannelkey(self, c, e):
        """Handle bad channel key error (475)"""
        channel = e.arguments()[1].lower() if len(e.arguments()) > 1 else None
        if channel:
            print "Bad channel key: %s" % channel
            self._schedule_channel_retry(channel)

    def on_nicknameinuse(self, c, e):
        """Nickname in use"""
        c.nick(c.get_nickname() + "_")

    def on_invite(self, c, e):
        """Arbitrarily join any channel invited to"""
        c.join(e.arguments()[0])
        #TODO: Save? Rewrite config file?

    ### Loggable events

    def on_action(self, c, e):
        """Someone says /me"""
        self.write_event("action", e)

    def on_join(self, c, e):
        """Handle successful channel joins"""
        channel = e.target().lower()
        nick = nm_to_n(e.source())
        
        # If it's our own join, remove from pending and failed lists
        if nick == c.get_nickname():
            if channel in self.pending_channels:
                self.pending_channels.remove(channel)
                print "Successfully joined: %s" % channel
            
            if channel in self.failed_channels:
                print "Retry successful for: %s" % channel
                del self.failed_channels[channel]
        
        self.write_event("join", e)

    def on_kick(self, c, e):
        self.write_event("kick", e,
                         {"%kicker%" : e.source(),
                          "%channel%" : e.target(),
                          "%user%" : e.arguments()[0],
                          "%reason%" : e.arguments()[1],
                         })

    def on_mode(self, c, e):
        self.write_event("mode", e,
                         {"%modes%" : e.arguments()[0],
                          "%person%" : e.arguments()[1] if len(e.arguments()) > 1 else e.target(),
                          "%giver%" : nm_to_n(e.source()),
                         })

    def on_nick(self, c, e):
        old_nick = nm_to_n(e.source())
        # Only write the event on channels that actually had the user in the channel
        for chan in self.channels:
            if old_nick in [x.lstrip('~%&@+') for x in self.channels[chan].users()]:
                self.write_event("nick", e,
                             {"%old%" : old_nick,
                              "%new%" : e.target(),
                              "%chan%": chan,
                             })

    def on_part(self, c, e):
        self.write_event("part", e)

    def on_pubmsg(self, c, e):
        if e.arguments()[0].startswith(NICK):
            c.privmsg(e.target(), self.format["help"])
        self.write_event("pubmsg", e)

    def on_pubnotice(self, c, e):
        self.write_event("pubnotice", e)

    def on_privmsg(self, c, e):
        print nm_to_n(e.source()), e.arguments()
        c.privmsg(nm_to_n(e.source()), self.format["help"])

    def on_quit(self, c, e):
        nick = nm_to_n(e.source())
        # Only write the event on channels that actually had the user in the channel
        for chan in self.channels:
            if nick in [x.lstrip('~%&@+') for x in self.channels[chan].users()]:
                self.write_event("quit", e, {"%chan%" : chan})

    def on_topic(self, c, e):
        self.write_event("topic", e)

    # Loads the channel - timezone-location pairs from the CHANNEL_LOCATIONS_FILE
    # See the README for details and example
    def load_channel_locations(self):
        self.channel_locations = {}
        if os.path.exists(CHANNEL_LOCATIONS_FILE):
            f = open(CHANNEL_LOCATIONS_FILE, 'r')
            self.channel_locations = dict((k.lower(), v) for k, v in dict([line.strip().split(None,1) for line in f.readlines()]).iteritems())

def connect_ftp():
    print "Using FTP %s..." % (FTP_SERVER)
    f = ftplib.FTP(FTP_SERVER, FTP_USER, FTP_PASS)
    f.cwd(FTP_FOLDER)
    return f

def main():
    # Create the logs directory
    if not os.path.exists(LOG_FOLDER):
        os.makedirs(LOG_FOLDER)
        write_string("%s/index.html" % LOG_FOLDER, html_header.replace("%title%", "Chat Logs"))

    # Start the bot
    bot = Logbot(SERVER, PORT, SERVER_PASS, CHANNELS, NICK, NICK_PASS)
    try:
        # Connect to FTP
        if FTP_SERVER:
            bot.set_ftp(connect_ftp())

        bot.start()
    except KeyboardInterrupt:
        if FTP_SERVER: bot.ftp.quit()
        bot.quit()


if __name__ == "__main__":
    main()
