#!/bin/bash
mcli admin user add minio loki $LOKI_S3_PASSWORD
mcli mb minio/loki
mcli admin policy add minio loki-private loki-user-policy.json
mcli admin policy set minio loki-private user=loki
