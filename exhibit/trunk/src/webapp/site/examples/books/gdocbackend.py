#!/usr/bin/env python

import sys
import cgi
from datetime import date
import simplejson
import gdata.spreadsheet.service

# GData Handling

def gdata_login():
    gd_client = gdata.spreadsheet.service.SpreadsheetsService()
    gd_client.email = 'email'
    gd_client.password = 'password'
    gd_client.source = 'Exhibit Submitter'
    gd_client.ProgrammaticLogin()
    return gd_client

def print_feed(feed):
  for entry in feed.entry:
    if isinstance(feed, gdata.spreadsheet.SpreadsheetsCellsFeed):
      print '%s %s' % (entry.title.text, entry.content.text)
    elif isinstance(feed, gdata.spreadsheet.SpreadsheetsListFeed):
      print '%s %s' % (entry.title.text, entry.content.text)
    else:
      print '%s' % (entry.title.text)

class SheetManager(object):
    def __init__(self, client):
        self.client = client

    def get_spreadsheet(self, name):
        for e in self.client.GetSpreadsheetsFeed().entry:
            if e.title.text == name:
                key = e.id.text.rsplit('/', 1)[1]
                return Spreadsheet(self.client, key)

class Spreadsheet(object):
    def __init__(self, client, key):
        self.client = client
        self.key = key
    
    def get_worksheet(self, name=None, index=None):
        entry = self.client.GetWorksheetsFeed(self.key).entry
        ws = None
        if name != None:
            for e in entry:
                if e.title.text.lower() == ws_name.lower(): 
                    ws = e
        elif index != None:
            if entry[index]: ws = entry[index]
        else:
            raise Exception()
        if ws:
            key = ws.id.text.split('/')[-1]
            return Worksheet(self.client, self.key, key)

class Worksheet(object):
    def __init__(self, client, ss_key, ws_key):
        self.client = client
        self.ss_key = ss_key
        self.ws_key = ws_key
        self.feed = self.client.GetCellsFeed(self.ss_key, self.ws_key)
        
    def insert_row(self, obj):
        return self.client.InsertRow(obj, self.ss_key, self.ws_key)

# HTTP Responses

def output_response(status, content_type, text):
    print "Status: " + status
    print "Content-type: " + content_type
    print
    print text
    sys.exit()

def output_error(msg):
    output_response('400 Bad Request', 'text/plain', msg)

def output_object(obj, callback):
    resp = simplejson.dumps(obj, indent=4)
    if callback:
        resp = "%s(%s)" % (callback, resp)
    output_response('200 Ok', 'text/javascript', resp)

# Request handling

form = cgi.FieldStorage()
callback = form.getvalue('callback', None)
exhibit_name = form.getvalue('exhibitName')
json = form.getvalue('message')

if not json:
    output_error('no message object provided')
    
if not exhibit_name:
    output_error('no exhibit name provided')

try:
    message = simplejson.loads(json)
except Exception, e:
    output_error('invalid message: %s' % (str(e)))

try:
    manager = SheetManager(gdata_login())
    worksheet = manager.get_spreadsheet('Books').get_worksheet(name='submissions')
    for r in message:
        r['added'] = '="' + str(date.today().isoformat()) + '"'
        worksheet.insert_row(r)
    output_object({'status': 'ok'}, callback)
except Exception, e:
    output_error(str(e) + "\n" + str(message))

