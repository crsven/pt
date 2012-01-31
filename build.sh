#!/bin/bash

sudo gem uninstall pt
gem build pt.gemspec
sudo gem install pt-0.5.gem --no-rdoc --no-ri
pt --curses
