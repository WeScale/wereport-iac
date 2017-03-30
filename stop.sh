#!/bin/bash

gcloud container --project "slavayssiere-sandbox" clusters delete "wereport" --quiet
gcloud compute --project "slavayssiere-sandbox" firewall-rules delete "wereport-network-allow-internal" --quiet
gcloud compute --project "slavayssiere-sandbox" firewall-rules delete "allow-wereport-backend" --quiet
gcloud compute --project "slavayssiere-sandbox" networks delete "wereport-network" --quiet
