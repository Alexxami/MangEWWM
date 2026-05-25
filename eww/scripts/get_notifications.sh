#!/bin/bash
makoctl list | jq -c '.data[] | {id: .id, summary: .summary, body: .body, app: .app, icon: .icon, urgency: .urgency, time: .time}'
