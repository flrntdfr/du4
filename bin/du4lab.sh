#!/bin/bash
# Florent Dufour - May 2021
# CLI for interecting with the lab backend


source ../.config/.du4lab.env

# Museums are added closed by default
add_museum() {
  echo "Adding $1"
  curl -X POST "$API_URL/rest/v1/my-museums" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{ 'collection': '"$1"', 'is_open': 'false' }"
}

add_museum $1
