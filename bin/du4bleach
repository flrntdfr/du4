#!/bin/bash

remove_metadata() {
  exiftool -all= -overwrite_original $1 > /dev/null 2>&1
  xattr -c $1 > /dev/null 2>&1
  echo "Bleached."
}

remove_metadata $1
