#!/bin/bash
# Wrapper script to maintain backward compatibility
cd "$(dirname "$0")"
exec ./scripts/deploy.sh "$@"